import request from '@/utils/request'

export interface PerfIndicator {
  id?: number
  indicatorCode: string
  indicatorName: string
  bizCategory: 'PERFORMANCE' | 'ABILITY' | 'ATTITUDE'
  scoringType: 'QUANTITATIVE' | 'QUALITATIVE'
  unit: string
  defaultWeight: number
  defaultFactorCode: string
  dataSource?: string
  scoringDesc?: string
  status: 0 | 1
  createBy?: number
  updateBy?: number
  createdAt?: string
  updatedAt?: string
  deleted?: number
}

export interface PageResult<T> {
  total: number
  pageNum: number
  pageSize: number
  list: T[]
}

export const getIndicatorPage = (params: {
  pageNum: number
  pageSize: number
  keyword?: string
  bizCategory?: string
  status?: number
}) => {
  return request<PageResult<PerfIndicator>>({
    url: '/perf/indicators',
    method: 'GET',
    params
  })
}

export const getActiveIndicators = () => {
  return request<PerfIndicator[]>({
    url: '/perf/indicators/active',
    method: 'GET'
  })
}

export const getIndicatorsByCategory = (bizCategory: string) => {
  return request<PerfIndicator[]>({
    url: `/perf/indicators/category/${bizCategory}`,
    method: 'GET'
  })
}

export const getIndicatorById = (id: number) => {
  return request<PerfIndicator>({
    url: `/perf/indicators/${id}`,
    method: 'GET'
  })
}

export const createIndicator = (data: PerfIndicator) => {
  return request<PerfIndicator>({
    url: '/perf/indicators',
    method: 'POST',
    data
  })
}

export const updateIndicator = (id: number, data: PerfIndicator) => {
  return request<PerfIndicator>({
    url: `/perf/indicators/${id}`,
    method: 'PUT',
    data
  })
}

export const deleteIndicator = (id: number) => {
  return request({
    url: `/perf/indicators/${id}`,
    method: 'DELETE'
  })
}

export const updateIndicatorStatus = (id: number, status: number) => {
  return request<PerfIndicator>({
    url: `/perf/indicators/${id}/status`,
    method: 'POST',
    params: { status }
  })
}
