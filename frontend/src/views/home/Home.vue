<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const currentTime = ref('')

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
  <div class="home-content">
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

    <el-card shadow="hover" class="info-card">
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
  </div>
</template>

<style scoped>
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