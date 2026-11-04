import request from '@/utils/request'

export interface PerfCycle {
  id?: number
  cycleCode: string
  cycleName: string
  cycleType: string
  startDate: string
  endDate: string
  selfDeadline: string
  managerDeadline: string
  hrDeadline: string
  finalDeadline: string
  status: 'DRAFT' | 'IN_PROGRESS' | 'CLOSED'
  publishedAt?: string
  finishedAt?: string
  remark?: string
  createBy?: number
  updateBy?: number
  createdAt?: string
  updatedAt?: string
  deleted?: number
  version?: number
}

export interface PageResult<T> {
  total: number
  pageNum: number
  pageSize: number
  list: T[]
}

export const getCyclePage = (params: {
  pageNum: number
  pageSize: number
  keyword?: string
  status?: string
}) => {
  return request<PageResult<PerfCycle>>({
    url: '/perf/cycles',
    method: 'GET',
    params
  })
}

export const getAllCycles = () => {
  return request<PerfCycle[]>({
    url: '/perf/cycles/all',
    method: 'GET'
  })
}

export const getActiveCycles = () => {
  return request<PerfCycle[]>({
    url: '/perf/cycles/active',
    method: 'GET'
  })
}

export const getCycleById = (id: number) => {
  return request<PerfCycle>({
    url: `/perf/cycles/${id}`,
    method: 'GET'
  })
}

export const createCycle = (data: PerfCycle) => {
  return request<PerfCycle>({
    url: '/perf/cycles',
    method: 'POST',
    data
  })
}

export const updateCycle = (id: number, data: PerfCycle) => {
  return request<PerfCycle>({
    url: `/perf/cycles/${id}`,
    method: 'PUT',
    data
  })
}

export const deleteCycle = (id: number) => {
  return request({
    url: `/perf/cycles/${id}`,
    method: 'DELETE'
  })
}

export const publishCycle = (id: number) => {
  return request<PerfCycle>({
    url: `/perf/cycles/${id}/publish`,
    method: 'POST'
  })
}

export const closeCycle = (id: number) => {
  return request<PerfCycle>({
    url: `/perf/cycles/${id}/close`,
    method: 'POST'
  })
}
