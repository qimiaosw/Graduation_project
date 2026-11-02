<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { health } from '@/api/health'
import { ElMessage } from 'element-plus'

const healthStatus = ref<any>(null)
const loading = ref(false)

const checkHealth = async () => {
  loading.value = true
  try {
    const res = await health()
    healthStatus.value = res.data
  } catch (error: any) {
    healthStatus.value = { error: error.message || 'Failed to connect to backend' }
    ElMessage.error('Backend connection failed')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  checkHealth()
})
</script>

<template>
  <div class="app-container">
    <el-card class="health-card">
      <template #header>
        <div class="card-header">
          <span>企业绩效管理系统 EPMS</span>
        </div>
      </template>
      <div v-if="loading" class="loading">Loading...</div>
      <div v-else-if="healthStatus">
        <el-descriptions :column="2" border v-if="healthStatus.status">
          <el-descriptions-item label="Status">{{ healthStatus.status }}</el-descriptions-item>
          <el-descriptions-item label="Service">{{ healthStatus.service }}</el-descriptions-item>
          <el-descriptions-item label="Timestamp">{{ healthStatus.timestamp }}</el-descriptions-item>
        </el-descriptions>
        <div v-else class="error">{{ healthStatus.error }}</div>
      </div>
    </el-card>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.app-container {
  padding: 20px;
  min-height: 100vh;
  background-color: #f5f7fa;
}

.health-card {
  max-width: 600px;
  margin: 0 auto;
}

.card-header {
  font-size: 18px;
  font-weight: bold;
}

.loading {
  padding: 20px;
  text-align: center;
  color: #909399;
}

.error {
  color: #f56c6c;
  padding: 20px;
}
</style>
