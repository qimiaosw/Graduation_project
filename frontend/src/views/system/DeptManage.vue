<template>
  <div class="dept-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>部门管理</span>
          <el-button type="primary" @click="handleAddRoot">新增顶级部门</el-button>
        </div>
      </template>

      <el-table
        :data="treeData"
        v-loading="loading"
        row-key="id"
        default-expand-all
        :tree-props="{ children: 'children' }"
        stripe
      >
        <el-table-column prop="deptName" label="部门名称" min-width="200" />
        <el-table-column prop="deptCode" label="部门编码" width="160" />
        <el-table-column label="负责人" width="140">
          <template #default="{ row }">{{ userMap.get(row.leaderUserId) || '-' }}</template>
        </el-table-column>
        <el-table-column prop="sortNo" label="排序" width="80" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag v-if="row.status === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleAddChild(row)">新增下级</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="90px">
        <el-form-item label="上级部门">
          <el-tree-select
            v-model="form.parentId"
            :data="parentOptions"
            :props="{ label: 'deptName', children: 'children' }"
            node-key="id"
            value-key="id"
            check-strictly
            clearable
            placeholder="不选表示顶级部门"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="部门编码" prop="deptCode">
          <el-input v-model="form.deptCode" placeholder="如 DEPT_TECH" />
        </el-form-item>
        <el-form-item label="部门名称" prop="deptName">
          <el-input v-model="form.deptName" />
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="form.leaderUserId" clearable filterable placeholder="请选择" style="width: 100%">
            <el-option
              v-for="user in users"
              :key="user.id"
              :label="`${user.realName}（${user.username}）`"
              :value="user.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sortNo" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import {
  getDeptList,
  createDept,
  updateDept,
  deleteDept,
  getUserPage
} from '@/api/system'
import type { SysDept, SysUserVO } from '@/api/system'

const loading = ref(false)
const submitting = ref(false)
const flatDepts = ref<SysDept[]>([])
const users = ref<SysUserVO[]>([])

const dialogVisible = ref(false)
const dialogMode = ref<'create' | 'edit'>('create')
const dialogTitle = ref('新增部门')
const formRef = ref<FormInstance>()
const form = reactive<SysDept & { id?: number }>({
  id: undefined,
  parentId: 0,
  deptCode: '',
  deptName: '',
  leaderUserId: null,
  sortNo: 0,
  status: 1
})

const formRules: FormRules = {
  deptCode: [{ required: true, message: '请输入部门编码', trigger: 'blur' }],
  deptName: [{ required: true, message: '请输入部门名称', trigger: 'blur' }]
}

// 扁平列表 -> 树
const buildTree = (list: SysDept[]): SysDept[] => {
  const map = new Map<number, SysDept>()
  list.forEach(item => map.set(item.id!, { ...item, children: [] } as any))
  const roots: SysDept[] = []
  map.forEach(node => {
    const parentId = node.parentId || 0
    const parent = map.get(parentId)
    if (parent) {
      ;(parent as any).children.push(node)
    } else {
      roots.push(node)
    }
  })
  return roots
}

const treeData = computed(() => buildTree(flatDepts.value))

// 新增/编辑时的上级可选树（编辑时排除自己和自己的子孙）
const parentOptions = computed(() => {
  const excludeId = dialogMode.value === 'edit' ? form.id : undefined
  const isDescendant = (node: SysDept): boolean => {
    if (!excludeId) return false
    if (node.id === excludeId) return true
    return (node as any).children?.some((child: SysDept) => isDescendant(child)) ?? false
  }
  const filterTree = (nodes: SysDept[]): SysDept[] => {
    return nodes
      .filter(node => node.id !== excludeId)
      .map(node => {
        const children = filterTree((node as any).children || [])
        return { ...node, children } as SysDept
      })
      .filter(node => !isDescendant(node as SysDept))
  }
  return filterTree(buildTree(flatDepts.value))
})

const userMap = computed(() => {
  const map = new Map<number, string>()
  users.value.forEach(user => map.set(user.id, user.realName))
  return map
})

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getDeptList()
    flatDepts.value = res.data
  } catch (error: any) {
    ElMessage.error(error?.message || '查询失败')
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  form.id = undefined
  form.parentId = 0
  form.deptCode = ''
  form.deptName = ''
  form.leaderUserId = null
  form.sortNo = 0
  form.status = 1
}

const handleAddRoot = () => {
  dialogMode.value = 'create'
  dialogTitle.value = '新增顶级部门'
  resetForm()
  dialogVisible.value = true
}

const handleAddChild = (row: SysDept) => {
  dialogMode.value = 'create'
  dialogTitle.value = `新增「${row.deptName}」的下级部门`
  resetForm()
  form.parentId = row.id
  dialogVisible.value = true
}

const handleEdit = (row: SysDept) => {
  dialogMode.value = 'edit'
  dialogTitle.value = '编辑部门'
  form.id = row.id
  form.parentId = row.parentId ?? 0
  form.deptCode = row.deptCode
  form.deptName = row.deptName
  form.leaderUserId = row.leaderUserId ?? null
  form.sortNo = row.sortNo ?? 0
  form.status = row.status ?? 1
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate()
  submitting.value = true
  try {
    const payload: SysDept = {
      parentId: form.parentId || 0,
      deptCode: form.deptCode,
      deptName: form.deptName,
      leaderUserId: form.leaderUserId ?? null,
      sortNo: form.sortNo,
      status: form.status
    }
    if (dialogMode.value === 'create') {
      await createDept(payload)
      ElMessage.success('新增成功')
    } else {
      await updateDept(form.id!, payload)
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

const handleDelete = async (row: SysDept) => {
  await ElMessageBox.confirm(`确定删除部门「${row.deptName}」吗？`, '提示', { type: 'warning' })
  try {
    await deleteDept(row.id!)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error: any) {
    ElMessage.error(error?.message || '删除失败')
  }
}

onMounted(async () => {
  fetchData()
  try {
    const res = await getUserPage({ pageNum: 1, pageSize: 100 })
    users.value = res.data.list
  } catch {
    // 负责人下拉属于辅助数据，加载失败不影响部门维护
  }
})
</script>

<style scoped>
.dept-container {
  padding: 0;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>