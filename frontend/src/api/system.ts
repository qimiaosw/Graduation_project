import request from '@/utils/request'

export interface PageResult<T> {
  total: number
  pageNum: number
  pageSize: number
  list: T[]
}

// ---------------------- 用户 ----------------------

export interface RoleDTO {
  id: number
  roleCode: string
  roleName: string
}

export interface SysUserVO {
  id: number
  username: string
  realName: string
  employeeNo?: string
  deptId?: number
  deptName?: string
  positionTitle?: string
  mobile?: string
  email?: string
  status: number
  createdAt?: string
  roles: RoleDTO[]
}

export interface CreateUserDTO {
  username: string
  realName: string
  employeeNo?: string
  deptId: number | null
  positionTitle?: string
  mobile?: string
  email?: string
  roleIds: number[]
}

export interface UpdateUserDTO {
  realName: string
  deptId: number | null
  positionTitle?: string
  mobile?: string
  email?: string
  roleIds: number[]
}

export const getUserPage = (params: {
  pageNum: number
  pageSize: number
  deptId?: number
  keyword?: string
  status?: number
}) => {
  return request<PageResult<SysUserVO>>({
    url: '/system/users',
    method: 'GET',
    params
  })
}

export const getUserById = (id: number) => {
  return request<SysUserVO>({ url: `/system/users/${id}`, method: 'GET' })
}

export const createUser = (data: CreateUserDTO) => {
  return request<number>({ url: '/system/users', method: 'POST', data })
}

export const updateUser = (id: number, data: UpdateUserDTO) => {
  return request<void>({ url: `/system/users/${id}`, method: 'PUT', data })
}

export const resetUserPassword = (id: number) => {
  return request<void>({ url: `/system/users/${id}/reset-password`, method: 'POST' })
}

export const updateUserStatus = (id: number, status: number) => {
  return request<void>({
    url: `/system/users/${id}/status`,
    method: 'POST',
    params: { status }
  })
}

// ---------------------- 部门 ----------------------

export interface SysDept {
  id?: number
  parentId?: number | null
  ancestors?: string
  deptCode: string
  deptName: string
  leaderUserId?: number | null
  sortNo?: number
  status?: number
}

export interface DeptTreeNode {
  id: number
  deptCode: string
  deptName: string
  parentId: number
  ancestors?: string
  leaderUserId?: number | null
  sortNo?: number
  status?: number
  children?: DeptTreeNode[]
}

export const getDeptList = () => {
  return request<SysDept[]>({ url: '/system/depts', method: 'GET' })
}

export const getDeptTree = () => {
  return request<DeptTreeNode[]>({ url: '/system/depts/tree', method: 'GET' })
}

export const getDeptById = (id: number) => {
  return request<SysDept>({ url: `/system/depts/${id}`, method: 'GET' })
}

export const createDept = (data: SysDept) => {
  return request<SysDept>({ url: '/system/depts', method: 'POST', data })
}

export const updateDept = (id: number, data: SysDept) => {
  return request<SysDept>({ url: `/system/depts/${id}`, method: 'PUT', data })
}

export const deleteDept = (id: number) => {
  return request<void>({ url: `/system/depts/${id}`, method: 'DELETE' })
}

// ---------------------- 角色 ----------------------

export interface SysRole {
  id?: number
  roleCode: string
  roleName: string
  dataScope?: string
  status?: number
  remark?: string
  createdAt?: string
}

export const getRoleList = () => {
  return request<SysRole[]>({ url: '/system/roles', method: 'GET' })
}

export const getRoleById = (id: number) => {
  return request<SysRole>({ url: `/system/roles/${id}`, method: 'GET' })
}