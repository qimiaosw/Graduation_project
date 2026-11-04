<template>
  <div class="cycle-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>考核周期管理</span>
          <el-button type="primary" @click="handleAdd">新增周期</el-button>
        </div>
      </template>

      <!-- 搜索区域 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="关键字">
          <el-input v-model="searchForm.keyword" placeholder="周期编码/名称" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="请选择" clearable>
            <el-option label="草稿" value="DRAFT" />
            <el-option label="进行中" value="IN_PROGRESS" />
            <el-option label="已关闭" value="CLOSED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格 -->
      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="cycleCode" label="周期编码" width="120" />
        <el-table-column prop="cycleName" label="周期名称" min-width="150" />
        <el-table-column prop="cycleType" label="周期类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.cycleType === 'QUARTER'">季度</el-tag>
            <el-tag v-else-if="row.cycleType === 'YEAR'" type="success">年度</el-tag>
            <el-tag v-else type="info">月度</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="考核时间" min-width="180">
          <template #default="{ row }">
            {{ row.startDate }} ~ {{ row.endDate }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'DRAFT'" type="info">草稿</el-tag>
            <el-tag v-else-if="row.status === 'IN_PROGRESS'" type="success">进行中</el-tag>
            <el-tag v-else-if="row.status === 'CLOSED'" type="danger">已关闭</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)" :disabled="row.status !== 'DRAFT'">编辑</el-button>
            <el-button type="success" link @click="handlePublish(row)" :disabled="row.status !== 'DRAFT'">发布</el-button>
            <el-button type="warning" link @click="handleClose(row)" :disabled="row.status !== 'IN_PROGRESS'">关闭</el-button>
            <el-button type="danger" link @click="handleDelete(row)" :disabled="row.status !== 'DRAFT'">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination
        v-model:current-page="pagination.pageNum"
        v-model:page-size="pagination.pageSize"
        :page-sizes="[10, 20, 50]"
        :total="pagination.total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="fetchData"
        @current-change="fetchData"
        style="margin-top: 20px; justify-content: flex-end;"
      />
    </el-card>

    <!-- 新增/编辑/详情弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="700px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="formRules" label-width="120px" :disabled="dialogMode === 'view'">
        <el-form-item label="周期编码" prop="cycleCode">
          <el-input v-model="form.cycleCode" placeholder="如：2026-Q1" />
        </el-form-item>
        <el-form-item label="周期名称" prop="cycleName">
          <el-input v-model="form.cycleName" placeholder="如：2026 年第一季度考核" />
        </el-form-item>
        <el-form-item label="周期类型" prop="cycleType">
          <el-select v-model="form.cycleType" placeholder="请选择">
            <el-option label="月度" value="MONTH" />
            <el-option label="季度" value="QUARTER" />
            <el-option label="年度" value="YEAR" />
          </el-select>
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="开始日期" prop="startDate">
              <el-date-picker v-model="form.startDate" type="date" value-format="YYYY-MM-DD" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束日期" prop="endDate">
              <el-date-picker v-model="form.endDate" type="date" value-format="YYYY-MM-DD" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="自评截止" prop="selfDeadline">
              <el-date-picker v-model="form.selfDeadline" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="部门评审截止" prop="managerDeadline">
              <el-date-picker v-model="form.managerDeadline" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="HR复核截止" prop="hrDeadline">
              <el-date-picker v-model="form.hrDeadline" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="终审截止" prop="finalDeadline">
              <el-date-picker v-model="form.finalDeadline" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ dialogMode === 'view' ? '关闭' : '取消' }}</el-button>
        <el-button v-if="dialogMode !== 'view'" type="primary" @click="handleSubmit" :loading="submitLoading">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { getCyclePage, createCycle, updateCycle, deleteCycle, publishCycle, closeCycle, type PerfCycle } from '@/api/perfCycle'

const loading = ref(false)
const submitLoading = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('')
const dialogMode = ref<'create' | 'edit' | 'view'>('create')
const formRef = ref<FormInstance>()

const tableData = ref<PerfCycle[]>([])

const searchForm = reactive({
  keyword: '',
  status: ''
})

const pagination = reactive({
  pageNum: 1,
  pageSize: 10,
  total: 0
})

const form = reactive<PerfCycle>({
  cycleCode: '',
  cycleName: '',
  cycleType: 'QUARTER',
  startDate: '',
  endDate: '',
  selfDeadline: '',
  managerDeadline: '',
  hrDeadline: '',
  finalDeadline: '',
  status: 'DRAFT',
  remark: ''
})

const formRules: FormRules = {
  cycleCode: [{ required: true, message: '请输入周期编码', trigger: 'blur' }],
  cycleName: [{ required: true, message: '请输入周期名称', trigger: 'blur' }],
  cycleType: [{ required: true, message: '请选择周期类型', trigger: 'change' }],
  startDate: [{ required: true, message: '请选择开始日期', trigger: 'change' }],
  endDate: [{ required: true, message: '请选择结束日期', trigger: 'change' }],
  selfDeadline: [{ required: true, message: '请选择自评截止时间', trigger: 'change' }],
  managerDeadline: [{ required: true, message: '请选择部门评审截止时间', trigger: 'change' }],
  hrDeadline: [{ required: true, message: '请选择HR复核截止时间', trigger: 'change' }],
  finalDeadline: [{ required: true, message: '请选择终审截止时间', trigger: 'change' }]
}

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getCyclePage({
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize,
      keyword: searchForm.keyword || undefined,
      status: searchForm.status || undefined
    })
    tableData.value = res.data.list
    pagination.total = res.data.total
  } catch (error: any) {
    ElMessage.error(error.message || '获取数据失败')
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
  searchForm.status = ''
  handleSearch()
}

const handleAdd = () => {
  dialogMode.value = 'create'
  dialogTitle.value = '新增周期'
  Object.assign(form, {
    id: undefined,
    cycleCode: '',
    cycleName: '',
    cycleType: 'QUARTER',
    startDate: '',
    endDate: '',
    selfDeadline: '',
    managerDeadline: '',
    hrDeadline: '',
    finalDeadline: '',
    status: 'DRAFT',
    remark: ''
  })
  dialogVisible.value = true
}

const handleEdit = (row: PerfCycle) => {
  dialogMode.value = 'edit'
  dialogTitle.value = '编辑周期'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleView = (row: PerfCycle) => {
  dialogMode.value = 'view'
  dialogTitle.value = '周期详情'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleSubmit = async () => {
  if (dialogMode.value === 'view') {
    dialogVisible.value = false
    return
  }
  if (!formRef.value) return
  await formRef.value.validate()
  
  submitLoading.value = true
  try {
    if (form.id) {
      await updateCycle(form.id, form)
      ElMessage.success('更新成功')
    } else {
      await createCycle(form)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error: any) {
    ElMessage.error(error.message || '操作失败')
  } finally {
    submitLoading.value = false
  }
}

const handleDelete = async (row: PerfCycle) => {
  try {
    await ElMessageBox.confirm('确定要删除该周期吗？', '提示', { type: 'warning' })
    await deleteCycle(row.id!)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

const handlePublish = async (row: PerfCycle) => {
  try {
    await ElMessageBox.confirm('发布后该周期将开始进行，确定要发布吗？', '提示', { type: 'warning' })
    await publishCycle(row.id!)
    ElMessage.success('发布成功')
    fetchData()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '发布失败')
    }
  }
}

const handleClose = async (row: PerfCycle) => {
  try {
    await ElMessageBox.confirm('关闭后该周期将不能再新增绩效记录，确定要关闭吗？', '提示', { type: 'warning' })
    await closeCycle(row.id!)
    ElMessage.success('关闭成功')
    fetchData()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '关闭失败')
    }
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.cycle-container {
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-form {
  margin-bottom: 20px;
}
</style>
