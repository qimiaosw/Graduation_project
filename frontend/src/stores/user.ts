import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login, logout, getCurrentUser, refreshToken as refreshTokenApi } from '@/api/auth'
import type { LoginRequest, LoginResponse } from '@/api/auth'
import router from '@/router'

export const useUserStore = defineStore('user', () => {
  const token = ref<string>('')
  const refreshToken = ref<string>('')
  const userInfo = ref<LoginResponse['userInfo'] | null>(null)

  const setToken = (accessToken: string, refresh: string) => {
    token.value = accessToken
    refreshToken.value = refresh
    localStorage.setItem('accessToken', accessToken)
    localStorage.setItem('refreshToken', refresh)
  }

  const setUserInfo = (info: LoginResponse['userInfo']) => {
    userInfo.value = info
  }

  const userLogin = async (data: LoginRequest) => {
    const res = await login(data)
    setToken(res.data.accessToken, res.data.refreshToken)
    setUserInfo(res.data.userInfo)
    return res.data
  }

  const userLogout = async () => {
    try {
      await logout(refreshToken.value)
    } catch (e) {
      // 即使失败也清理本地状态
    }
    token.value = ''
    refreshToken.value = ''
    userInfo.value = null
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    router.push('/login')
  }

  const fetchUserInfo = async () => {
    const res = await getCurrentUser()
    userInfo.value = res.data
    return res.data
  }

  // 用 refreshToken 换新的 accessToken 和 refreshToken，并更新本地存储
  const refreshAccessToken = async () => {
    const res = await refreshTokenApi(refreshToken.value)
    setToken(res.data.accessToken, res.data.refreshToken)
    return res.data.accessToken
  }

  const initFromStorage = () => {
    const t = localStorage.getItem('accessToken')
    const rt = localStorage.getItem('refreshToken')
    if (t && rt) {
      token.value = t
      refreshToken.value = rt
    }
  }

  const hasToken = () => {
    return !!token.value
  }

  // 检查是否具有某个角色
  const hasRole = (role: string) => {
    const roles = userInfo.value?.roles
    return roles ? roles.includes(role) : false
  }

  return {
    token,
    refreshToken,
    userInfo,
    setToken,
    setUserInfo,
    userLogin,
    userLogout,
    fetchUserInfo,
    refreshAccessToken,
    initFromStorage,
    hasToken,
    hasRole
  }
})
