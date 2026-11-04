<template>
  <div class="user-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" @click="handleAdd">新增用户</el-button>
        </div>
      </template>

      <!-- 搜索区域 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="关键字">
          <el-input
            v-model="searchForm.keyword"
            placeholder="用户名/姓名/工号"
            clearable
            @keyup.enter="handleSearch"
          />
        </el-form-item>
        <el-form-item label="部门">
          <el-tree-select
            v-model="searchForm.deptId"
            :data="deptTree"
            :props="{ label: 'deptName', children: 'children' }"
            node-key="id"
            value-key="id"
            check-strictly
            clearable
            placeholder="请选择部门"
            style="width: 180px"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="全部" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="realName" label="姓名" width="100" />
        <el-table-column prop="employeeNo" label="工号" width="100" />
        <el-table-column prop="deptName" label="部门" min-width="120" />
        <el-table-column prop="positionTitle" label="岗位" min-width="120" />
        <el-table-column label="角色" min-width="180">
          <template #default="{ row }">
            <el-tag v-for="role in row.roles" :key="role.id" size="small" style="margin-right: 4px">
              {{ role.roleName }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="mobile" label="手机号" width="130" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag v-if="row.status === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="warning" link @click="handleResetPassword(row)">重置密码</el-button>
            <el-button
              :type="row.status === 1 ? 'danger' : 'success'"
              link
              @click="handleToggleStatus(row)"
            >
              {{ row.status === 1 ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pagination.pageNum"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 20px; justify-content: flex-end"
        @size-change="fetchData"
        @current-change="fetchData"
      />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="640px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="90px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" :disabled="dialogMode !== 'create'" placeholder="字母/数字/下划线" />
        </el-form-item>
        <el-form-item label="姓名" prop="realName">
          <el-input v-model="form.realName" />
        </el-form-item>
        <el-form-item label="工号">
          <el-input v-model="form.employeeNo" />
        </el-form-item>
        <el-form-item label="部门" prop="deptId">
          <el-tree-select
            v-model="form.deptId"
            :data="deptTree"
            :props="{ label: 'deptName', children: 'children' }"
            node-key="id"
            value-key="id"
            check-strictly
            placeholder="请选择部门"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="岗位">
          <el-input v-model="form.positionTitle" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="form.mobile" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" />
        </el-form-item>
        <el-form-item label="角色" prop="roleIds">
          <el-select v-model="form.roleIds" multiple placeholder="请选择角色" style="width: 100%">
            <el-option v-for="role in roles" :key="role.id" :label="role.roleName" :value="role.id!" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog v-model="viewVisible" title="用户详情" width="620px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="用户名">{{ detail.username }}</el-descriptions-item>
        <el-descriptions-item label="姓名">{{ detail.realName }}</el-descriptions-item>
        <el-descriptions-item label="工号">{{ detail.employeeNo || '-' }}</el-descriptions-item>
        <el-descriptions-item label="部门">{{ detail.deptName || '-' }}</el-descriptions-item>
        <el-descriptions-item label="岗位">{{ detail.positionTitle || '-' }}</el-descriptions-item>
        <el-descriptions-item label="手机号">{{ detail.mobile || '-' }}</el-descriptions-item>
        <el-descriptions-item label="邮箱">{{ detail.email || '-' }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="detail.status === 1 ? 'success' : 'danger'">
            {{ detail.status === 1 ? '启用' : '停用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="角色" :span="2">
          <el-tag v-for="role in detail.roles" :key="role.id" size="small" style="margin-right: 4px">
            {{ role.roleName }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">{{ detail.createdAt || '-' }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="viewVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import {
  getUserPage,
  getUserById,
  createUser,
  resetUserPassword,
  updateUserStatus,
  updateUser,
  getDeptTree,
  getRoleList
} from '@/api/system'
import type { SysUserVO, DeptTreeNode, SysRole, CreateUserDTO } from '@/api/system'

const loading = ref(false)
const submitting = ref(false)
const tableData = ref<SysUserVO[]>([])
const deptTree = ref<DeptTreeNode[]>([])
const roles = ref<SysRole[]>([])

const searchForm = reactive<{ keyword: string; deptId: number | undefined; status: number | undefined }>({
  keyword: '',
  deptId: undefined,
  status: undefined
})

const pagination = reactive({ pageNum: 1, pageSize: 10, total: 0 })

const dialogVisible = ref(false)
const dialogMode = ref<'create' | 'edit'>('create')
const dialogTitle = ref('新增用户')
const formRef = ref<FormInstance>()
const form = reactive<CreateUserDTO & { id?: number }>({
  id: undefined,
  username: '',
  realName: '',
  employeeNo: '',
  deptId: null,
  positionTitle: '',
  mobile: '',
  email: '',
  roleIds: []
})

const viewVisible = ref(false)
const detail = ref<Partial<SysUserVO>>({})

const formRules: FormRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_]+$/, message: '只能包含字母、数字和下划线', trigger: 'blur' }
  ],
  realName: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  deptId: [{ required: true, message: '请选择部门', trigger: 'change' }],
  roleIds: [{ required: true, message: '至少选择一个角色', trigger: 'change' }]
}

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getUserPage({
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize,
      keyword: searchForm.keyword || undefined,
      deptId: searchForm.deptId,
      status: searchForm.status
    })
    tableData.value = res.data.list
    pagination.total = res.data.total
  } catch (error: any) {
    ElMessage.error(error?.message || '查询失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.pageNum = 1
  fetchData()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.deptId = undefined
  searchForm.status = undefined
  handleSearch()
}

const resetForm = () => {
  form.id = undefined
  form.username = ''
  form.realName = ''
  form.employeeNo = ''
  form.deptId = null
  form.positionTitle = ''
  form.mobile = ''
  form.email = ''
  form.roleIds = []
}

const handleAdd = () => {
  dialogMode.value = 'create'
  dialogTitle.value = '新增用户'
  resetForm()
  dialogVisible.value = true
}

const handleEdit = async (row: SysUserVO) => {
  dialogMode.value = 'edit'
  dialogTitle.value = '编辑用户'
  resetForm()
  const res = await getUserById(row.id)
  const user = res.data
  form.id = user.id
  form.username = user.username
  form.realName = user.realName
  form.employeeNo = user.employeeNo || ''
  form.deptId = user.deptId ?? null
  form.positionTitle = user.positionTitle || ''
  form.mobile = user.mobile || ''
  form.email = user.email || ''
  form.roleIds = (user.roles || []).map(role => role.id)
  dialogVisible.value = true
}

const handleView = async (row: SysUserVO) => {
  const res = await getUserById(row.id)
  detail.value = res.data
  viewVisible.value = true
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate()
  submitting.value = true
  try {
    if (dialogMode.value === 'create') {
      await createUser({
        username: form.username,
        realName: form.realName,
        employeeNo: form.employeeNo || undefined,
        deptId: form.deptId,
        positionTitle: form.positionTitle || undefined,
        mobile: form.mobile || undefined,
        email: form.email || undefined,
        roleIds: form.roleIds
      })
      ElMessage.success('新增成功，初始密码 Epms@123456')
    } else {
      await updateUser(form.id!, {
        realName: form.realName,
        deptId: form.deptId,
        positionTitle: form.positionTitle || undefined,
        mobile: form.mobile || undefined,
        email: form.email || undefined,
        roleIds: form.roleIds
      })
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error: any) {
    ElMessage.error(error?.message || '保存失败')
  } finally {
    submitting.value = false
  }
}

const handleResetPassword = async (row: SysUserVO) => {
  await ElMessageBox.confirm(`确定把「${row.realName}」的密码重置为初始密码吗？`, '提示', {
    type: 'warning'
  })
  try {
    await resetUserPassword(row.id)
    ElMessage.success('密码已重置为 Epms@123456')
  } catch (error: any) {
    ElMessage.error(error?.message || '重置失败')
  }
}

const handleToggleStatus = async (row: SysUserVO) => {
  const next = row.status === 1 ? 0 : 1
  const action = next === 1 ? '启用' : '停用'
  await ElMessageBox.confirm(
    next === 0 ? `停用「${row.realName}」后其登录会话会立即失效，确定继续吗？` : `确定启用「${row.realName}」吗？`,
    '提示',
    { type: 'warning' }
  )
  try {
    await updateUserStatus(row.id, next)
    ElMessage.success(`${action}成功`)
    fetchData()
  } catch (error: any) {
    ElMessage.error(error?.message || `${action}失败`)
  }
}

onMounted(async () => {
  try {
    const [deptRes, roleRes] = await Promise.all([getDeptTree(), getRoleList()])
    deptTree.value = deptRes.data
    roles.value = roleRes.data
  } catch (error: any) {
    ElMessage.error(error?.message || '加载部门/角色下拉数据失败')
  }
  fetchData()
})
</script>

<style scoped>
.user-container {
  padding: 0;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.search-form {
  margin-bottom: 12px;
}
</style>