import axios, { AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'

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

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const res = response.data
    if (res.code !== 0) {
      if (res.code === 40101) {
        localStorage.removeItem('accessToken')
        window.location.href = '/login'
      }
      ElMessage.error(res.message || 'Error')
      return Promise.reject(new Error(res.message || 'Error'))
    }
    return response.data
  },
  (error) => {
    ElMessage.error(error.message || 'Network Error')
    return Promise.reject(error)
  }
)

export default request
