import axios, { AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from 'axios'

const service = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 30000
})

/**
 * 后端统一响应结构 R<T>。
 * 响应拦截器解包后返回的就是这个对象（即 response.data），
 * 业务数据在 .data 字段中。
 */
export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
  traceId: string | null
}

/**
 * 经过响应拦截器解包后，request<T> 返回 Promise<ApiResponse<T>>。
 */
interface RequestInstance {
  <T = any>(config: AxiosRequestConfig): Promise<ApiResponse<T>>
  <T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>>
  get<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>>
  post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>>
  put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<ApiResponse<T>>
  delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<ApiResponse<T>>
}

const request = service as unknown as RequestInstance

service.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('accessToken')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 会话级错误码：未认证 / token 过期 / 会话被踢（账号停用、被顶下线）
const SESSION_ERROR_CODES = [40100, 40101, 40102]

// 跳登录页，并带上过期标记，登录页会提示"登录状态已失效"
function redirectToLogin(message?: string) {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  if (window.location.pathname.startsWith('/login')) {
    return
  }
  if (message) {
    sessionStorage.setItem('loginNotice', message)
  }
  const current = window.location.pathname + window.location.search
  window.location.href = `/login?expired=1&redirect=${encodeURIComponent(current)}`
}

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const res = response.data
    if (res.code !== 0) {
      const url = response.config.url || ''
      // 登录接口本身的 40100 是"用户名或密码错误"，不能当成会话失效应跳转
      const isLoginRequest = url.includes('/auth/login')
      if (!isLoginRequest && SESSION_ERROR_CODES.includes(res.code)) {
        redirectToLogin(res.code === 40102 ? '账号已在别处失效或已被停用，请重新登录' : '登录状态已失效，请重新登录')
      }
      // 把业务错误码挂到 error 上，业务层可按 code 精确区分提示，不再依赖字符串匹配
      const err = new Error(res.message || 'Error') as Error & { code?: number; traceId?: string | null }
      err.code = res.code
      err.traceId = res.traceId ?? null
      // 不在这里弹消息，让业务层自己处理
      return Promise.reject(err)
    }
    return response.data
  },
  (error) => {
    // 网络层异常保留原始信息（如 Network Error / timeout），由业务层给出中文提示
    return Promise.reject(error)
  }
)

export default request
