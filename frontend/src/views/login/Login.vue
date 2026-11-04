<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const loginForm = reactive({
  username: '',
  password: ''
})

const loading = ref(false)

// 被踢下线 / token 过期跳回来时，把原因提示出来
onMounted(() => {
  const notice = sessionStorage.getItem('loginNotice')
  if (notice || route.query.expired) {
    ElMessage.warning(notice || '登录状态已失效，请重新登录')
    sessionStorage.removeItem('loginNotice')
  }
})

const handleLogin = async () => {
  if (!loginForm.username || !loginForm.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }

  loading.value = true
  try {
    await userStore.userLogin(loginForm)
    ElMessage.success('登录成功')
    const redirect = route.query.redirect as string
    router.push(redirect || '/')
  } catch (error: any) {
    // request.ts 已把后端业务码挂到 error.code，优先按码精确区分提示
    const code = error?.code as number | undefined
    const msg = error?.message || ''
    if (code === 40301 || code === 40300) {
      ElMessage.error('账号已被停用，请联系管理员')
    } else if (code === 40100 || code === 40101) {
      ElMessage.error('用户名或密码错误')
    } else if (code === 42900) {
      ElMessage.error('登录尝试过于频繁，请稍后再试')
    } else if (code === 40001) {
      ElMessage.error(msg || '用户名或密码不能为空')
    } else if (msg.includes('Network Error') || msg.includes('ECONNREFUSED') || msg.includes('timeout')) {
      ElMessage.error('网络错误，请检查网络连接')
    } else {
      // 默认显示后端返回的消息
      ElMessage.error(msg || '登录失败，请稍后重试')
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login-container">
    <div class="login-box">
      <div class="login-header">
        <h1>企业绩效管理系统</h1>
      </div>
      <el-form :model="loginForm" @submit.prevent="handleLogin">
        <el-form-item>
          <el-input
            v-model="loginForm.username"
            placeholder="账号"
            :prefix-icon="User"
            size="large"
          />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="密码"
            :prefix-icon="Lock"
            size="large"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            style="width: 100%"
            @click="handleLogin"
          >
            登 录
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f2f5;
}

.login-box {
  width: 360px;
  padding: 40px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.login-header {
  text-align: center;
  margin-bottom: 32px;
}

.login-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 500;
  color: #333;
}
</style>
