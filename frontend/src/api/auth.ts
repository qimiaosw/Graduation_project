import request from '@/utils/request'

export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  accessToken: string
  refreshToken: string
  userInfo: {
    id: number
    username: string
    realName: string
    deptId?: number
    deptName?: string
  }
}

export const login = (data: LoginRequest) => {
  return request<LoginResponse>({
    url: '/auth/login',
    method: 'POST',
    data
  })
}

export const logout = (refreshToken: string) => {
  return request({
    url: '/auth/logout',
    method: 'POST',
    data: { refreshToken }
  })
}

export interface RefreshResponse {
  accessToken: string
  refreshToken: string
}

export const refreshToken = (refreshToken: string) => {
  return request<RefreshResponse>({
    url: '/auth/refresh',
    method: 'POST',
    data: { refreshToken }
  })
}

export const getCurrentUser = () => {
  return request<LoginResponse['userInfo']>({
    url: '/auth/me',
    method: 'GET'
  })
}
