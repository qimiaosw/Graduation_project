import request from '@/utils/request'

export interface HealthResponse {
  status: string
  service: string
  timestamp: string
}

export const health = () => {
  return request({
    url: '/health',
    method: 'GET'
  })
}
