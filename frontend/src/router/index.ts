import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/views/layout/Layout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'Home',
        component: () => import('@/views/home/Home.vue')
      },
      {
        path: 'perf/cycle',
        name: 'CycleManage',
        component: () => import('@/views/perf/CycleManage.vue'),
        meta: { roles: ['ADMIN', 'HR_SPECIALIST'] }
      },
      {
        path: 'perf/indicator',
        name: 'IndicatorManage',
        component: () => import('@/views/perf/IndicatorManage.vue'),
        meta: { roles: ['ADMIN', 'HR_SPECIALIST'] }
      },
      {
        path: 'system/user',
        name: 'UserManage',
        component: () => import('@/views/system/UserManage.vue'),
        meta: { roles: ['ADMIN', 'HR_SPECIALIST'] }
      },
      {
        path: 'system/dept',
        name: 'DeptManage',
        component: () => import('@/views/system/DeptManage.vue'),
        meta: { roles: ['ADMIN'] }
      },
      {
        path: 'system/role',
        name: 'RoleManage',
        component: () => import('@/views/system/RoleManage.vue'),
        meta: { roles: ['ADMIN', 'HR_SPECIALIST'] }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局路由守卫：登录态校验 + 角色校验
router.beforeEach(async (to, _from, next) => {
  const userStore = useUserStore()
  userStore.initFromStorage()

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth !== false)

  if (requiresAuth && !userStore.hasToken()) {
    // 需要登录但没有 token，跳转登录页并记住来源
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }

  if (to.name === 'Login' && userStore.hasToken()) {
    // 已登录却访问登录页，跳回首页
    next({ name: 'Home' })
    return
  }

  // 刷新页面后内存里的 userInfo 会丢，这里补一次，否则角色校验会把有权限的用户踢回首页
  if (userStore.hasToken() && !userStore.userInfo) {
    try {
      await userStore.fetchUserInfo()
    } catch {
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }
  }

  if (to.meta.roles) {
    const roles = to.meta.roles as string[]
    const hasPermission = roles.some(role => userStore.hasRole(role))
    if (!hasPermission) {
      next({ name: 'Home' })
      return
    }
  }

  next()
})

export default router