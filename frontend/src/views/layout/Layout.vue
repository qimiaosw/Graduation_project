<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const currentTime = ref('')

// 角色判断
const hasRole = (role: string) => userStore.hasRole(role)

// 菜单项：path 为真实路由，未实现的菜单不渲染
const menuItems = computed(() => {
  const items = [
    { index: 'home', title: '我的绩效', path: '/', roles: ['EMPLOYEE', 'DEPT_MANAGER', 'HR_SPECIALIST', 'EXECUTIVE', 'ADMIN'] },
    { index: 'cycle', title: '考核周期', path: '/perf/cycle', roles: ['ADMIN', 'HR_SPECIALIST'] },
    { index: 'indicator', title: '指标库', path: '/perf/indicator', roles: ['ADMIN', 'HR_SPECIALIST'] }
  ]
  return items.filter(item => item.roles.some(role => hasRole(role)))
})

// 系统管理子菜单：用户/部门/角色（后端接口均已实现）
const systemMenus = computed(() => {
  const items = [
    { index: 'user', title: '用户管理', path: '/system/user', roles: ['ADMIN', 'HR_SPECIALIST'] },
    { index: 'dept', title: '部门管理', path: '/system/dept', roles: ['ADMIN'] },
    { index: 'role', title: '角色管理', path: '/system/role', roles: ['ADMIN', 'HR_SPECIALIST'] }
  ]
  return items.filter(item => item.roles.some(role => hasRole(role)))
})

// 当前激活菜单由路由决定
const activeMenu = computed(() => {
  const all = [...menuItems.value, ...systemMenus.value]
  const matched = all.find(item => item.path === route.path)
  return matched ? matched.index : 'home'
})

const handleMenuClick = (index: string) => {
  const all = [...menuItems.value, ...systemMenus.value]
  const item = all.find(i => i.index === index)
  if (item) {
    router.push(item.path)
  }
}

const handleLogout = async () => {
  await userStore.userLogout()
  ElMessage.success('已退出')
}

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

let timeInterval: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  userStore.initFromStorage()
  if (!userStore.hasToken()) {
    router.push('/login')
    return
  }
  userStore.fetchUserInfo().catch(() => {
    ElMessage.error('获取用户信息失败')
    userStore.userLogout()
  })
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
})

onUnmounted(() => {
  if (timeInterval) {
    clearInterval(timeInterval)
    timeInterval = null
  }
})
</script>

<template>
  <div class="layout">
    <el-container class="layout-container">
      <el-header class="header">
        <div class="header-title">企业绩效管理系统</div>
        <div class="header-user">
          <span class="header-time">{{ currentTime }}</span>
          <span>{{ userStore.userInfo?.realName || userStore.userInfo?.username }}</span>
          <el-button type="danger" link @click="handleLogout">退出</el-button>
        </div>
      </el-header>

      <el-container>
        <el-aside width="200px" class="sidebar">
          <el-menu
            :default-active="activeMenu"
            class="sidebar-menu"
            @select="handleMenuClick"
          >
            <el-menu-item v-for="item in menuItems" :key="item.index" :index="item.index">
              <span>{{ item.title }}</span>
            </el-menu-item>
            <el-sub-menu v-if="systemMenus.length" index="system">
              <template #title>
                <span>系统管理</span>
              </template>
              <el-menu-item
                v-for="item in systemMenus"
                :key="item.index"
                :index="item.index"
              >
                <span>{{ item.title }}</span>
              </el-menu-item>
            </el-sub-menu>
          </el-menu>
        </el-aside>

        <el-main class="main-content">
          <router-view />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<style scoped>
.layout {
  height: 100vh;
}

.layout-container {
  height: 100%;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #fff;
  border-bottom: 1px solid #e4e7ed;
  padding: 0 20px;
}

.header-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.header-user {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #606266;
}

.header-time {
  color: #909399;
  font-size: 13px;
}

.sidebar {
  background-color: #fff;
  border-right: 1px solid #e4e7ed;
}

.sidebar-menu {
  border-right: none;
}

.main-content {
  background-color: #f5f7fa;
  padding: 20px;
}
</style>