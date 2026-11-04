<template>
  <div class="role-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>角色管理</span>
        </div>
      </template>

      <el-alert
        type="info"
        :closable="false"
        show-icon
        title="系统内置 5 个固定角色，角色编码与数据范围由 docs/03 接口契约定义；如需调整请改初始化脚本，接口只提供查询。"
        style="margin-bottom: 16px"
      />

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="roleCode" label="角色编码" width="180" />
        <el-table-column prop="roleName" label="角色名称" width="140" />
        <el-table-column label="数据范围" width="180">
          <template #default="{ row }">
            <el-tag v-if="row.dataScope === 'ALL'" type="danger">全部数据</el-tag>
            <el-tag v-else-if="row.dataScope === 'DEPT_TREE'" type="warning">本部门及下级</el-tag>
            <el-tag v-else type="info">仅本人</el-tag>
            <span style="margin-left: 6px; color: #909399">{{ row.dataScope }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="说明" min-width="220" show-overflow-tooltip />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="viewVisible" title="角色详情" width="520px">
      <el-descriptions :column="1" border>
        <el-descriptions-item label="角色编码">{{ detail.roleCode }}</el-descriptions-item>
        <el-descriptions-item label="角色名称">{{ detail.roleName }}</el-descriptions-item>
        <el-descriptions-item label="数据范围">{{ detail.dataScope }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ detail.status === 1 ? '启用' : '停用' }}</el-descriptions-item>
        <el-descriptions-item label="说明">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="viewVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getRoleList, getRoleById } from '@/api/system'
import type { SysRole } from '@/api/system'

const loading = ref(false)
const tableData = ref<SysRole[]>([])
const viewVisible = ref(false)
const detail = ref<Partial<SysRole>>({})

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getRoleList()
    tableData.value = res.data
  } catch (error: any) {
    ElMessage.error(error?.message || '查询失败')
  } finally {
    loading.value = false
  }
}

const handleView = async (row: SysRole) => {
  try {
    const res = await getRoleById(row.id!)
    detail.value = res.data
    viewVisible.value = true
  } catch (error: any) {
    ElMessage.error(error?.message || '查询详情失败')
  }
}

onMounted(fetchData)
</script>

<style scoped>
.role-container {
  padding: 0;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>