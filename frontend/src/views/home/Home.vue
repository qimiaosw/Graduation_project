<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()
const currentTime = ref('')

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

// 角色判断
const hasRole = (role: string) => {
  return userStore.hasRole(role)
}

// 菜单项
const menuItems = computed(() => {
  const items = [
    { index: '1', title: '我的绩效', roles: ['EMPLOYEE', 'DEPT_MANAGER', 'HR_SPECIALIST', 'EXECUTIVE', 'ADMIN'] },
    { index: '2', title: '审批工作台', roles: ['DEPT_MANAGER', 'HR_SPECIALIST', 'EXECUTIVE', 'ADMIN'] },
    { index: '3', title: '统计分析', roles: ['DEPT_MANAGER', 'HR_SPECIALIST', 'EXECUTIVE', 'ADMIN'] },
    { index: '4', title: '系统管理', roles: ['ADMIN', 'HR_SPECIALIST'] }
  ]
  
  // 根据用户角色过滤菜单
  return items.filter(item => {
    return item.roles.some(role => hasRole(role))
  })
})

// 定时器引用
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
  <div class="home-layout">
    <el-container>
      <el-header class="header">
        <div class="header-title">企业绩效管理系统</div>
        <div class="header-user">
          <span>{{ userStore.userInfo?.realName || userStore.userInfo?.username }}</span>
          <el-button type="danger" link @click="handleLogout">退出</el-button>
        </div>
      </el-header>

      <el-container>
        <el-aside width="200" class="sidebar">
          <el-menu
            :default-active="menuItems[0]?.index || '1'"
            class="sidebar-menu"
          >
            <el-menu-item 
              v-for="item in menuItems" 
              :key="item.index" 
              :index="item.index"
            >
              <span>{{ item.title }}</span>
            </el-menu-item>
          </el-menu>
        </el-aside>

        <el-main class="main-content">
          <el-row :gutter="16">
            <el-col :span="6">
              <el-card shadow="hover" class="stat-card">
                <div class="stat-label">待办任务</div>
                <div class="stat-value">0</div>
              </el-card>
            </el-col>
            <el-col :span="6">
              <el-card shadow="hover" class="stat-card">
                <div class="stat-label">已提交</div>
                <div class="stat-value">0</div>
              </el-card>
            </el-col>
            <el-col :span="6">
              <el-card shadow="hover" class="stat-card">
                <div class="stat-label">待审批</div>
                <div class="stat-value">0</div>
              </el-card>
            </el-col>
            <el-col :span="6">
              <el-card shadow="hover" class="stat-card">
                <div class="stat-label">消息</div>
                <div class="stat-value">0</div>
              </el-card>
            </el-col>
          </el-row>

          <el-card shadow="hover" class="info-card" style="margin-top: 16px;">
            <template #header>
              <span>基本信息</span>
            </template>
            <el-descriptions :column="2" border>
              <el-descriptions-item label="姓名">{{ userStore.userInfo?.realName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="部门">{{ userStore.userInfo?.deptName || '-' }}</el-descriptions-item>
              <el-descriptions-item label="账号">{{ userStore.userInfo?.username || '-' }}</el-descriptions-item>
              <el-descriptions-item label="时间">{{ currentTime }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<style scoped>
.home-layout {
  height: 100vh;
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
}

.stat-card {
  text-align: center;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 28px;
  font-weight: 600;
  color: #409eff;
}

.info-card {
  margin-top: 16px;
}
</style>
