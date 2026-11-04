<template>
  <div class="indicator-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>指标库管理</span>
          <el-button type="primary" @click="handleAdd">新增指标</el-button>
        </div>
      </template>

      <!-- 搜索区域 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="关键字">
          <el-input v-model="searchForm.keyword" placeholder="指标编码/名称" clearable @keyup.enter="handleSearch" />
        </el-form-item>
        <el-form-item label="业务分类">
          <el-select v-model="searchForm.bizCategory" placeholder="请选择" clearable>
            <el-option label="业绩" value="PERFORMANCE" />
            <el-option label="能力" value="ABILITY" />
            <el-option label="态度" value="ATTITUDE" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="searchForm.status" placeholder="请选择" clearable>
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 表格 -->
      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="indicatorCode" label="指标编码" width="150" />
        <el-table-column prop="indicatorName" label="指标名称" min-width="150" />
        <el-table-column prop="bizCategory" label="业务分类" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.bizCategory === 'PERFORMANCE'" type="danger">业绩</el-tag>
            <el-tag v-else-if="row.bizCategory === 'ABILITY'" type="warning">能力</el-tag>
            <el-tag v-else-if="row.bizCategory === 'ATTITUDE'" type="success">态度</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="scoringType" label="评分类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.scoringType === 'QUANTITATIVE'" type="primary">定量</el-tag>
            <el-tag v-else type="info">定性</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="unit" label="单位" width="80" />
        <el-table-column prop="defaultWeight" label="默认权重" width="100">
          <template #default="{ row }">
            {{ row.defaultWeight }}%
          </template>
        </el-table-column>
        <el-table-column prop="defaultFactorCode" label="决策因子" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag v-if="row.status === 1" type="success">启用</el-tag>
            <el-tag v-else type="danger">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link @click="handleView(row)">详情</el-button>
            <el-button type="primary" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="success" link @click="handleToggleStatus(row)" v-if="row.status === 0">启用</el-button>
            <el-button type="warning" link @click="handleToggleStatus(row)" v-else>停用</el-button>
            <el-button type="danger" link @click="handleDelete(row)">删除</el-button>
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
        <el-form-item label="指标编码" prop="indicatorCode">
          <el-input v-model="form.indicatorCode" placeholder="如：KPI-SALE-01" />
        </el-form-item>
        <el-form-item label="指标名称" prop="indicatorName">
          <el-input v-model="form.indicatorName" placeholder="如：销售额" />
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="业务分类" prop="bizCategory">
              <el-select v-model="form.bizCategory" placeholder="请选择">
                <el-option label="业绩" value="PERFORMANCE" />
                <el-option label="能力" value="ABILITY" />
                <el-option label="态度" value="ATTITUDE" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="评分类型" prop="scoringType">
              <el-select v-model="form.scoringType" placeholder="请选择">
                <el-option label="定量" value="QUANTITATIVE" />
                <el-option label="定性" value="QUALITATIVE" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="单位" prop="unit">
              <el-input v-model="form.unit" placeholder="如：万元、%、个" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="默认权重" prop="defaultWeight">
              <el-input-number v-model="form.defaultWeight" :min="0" :max="100" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="决策因子" prop="defaultFactorCode">
          <el-select v-model="form.defaultFactorCode" placeholder="请选择">
            <el-option label="F1 量化指标达成率" value="F1" />
            <el-option label="F2 重点工作完成质量" value="F2" />
            <el-option label="F3 价值观与行为规范" value="F3" />
            <el-option label="F4 出勤与合规" value="F4" />
            <el-option label="F5 能力成长" value="F5" />
            <el-option label="F6 协作与历史趋势" value="F6" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据来源" prop="dataSource">
          <el-input v-model="form.dataSource" placeholder="如：销售系统导出、主管评分" />
        </el-form-item>
        <el-form-item label="计分口径" prop="scoringDesc">
          <el-input v-model="form.scoringDesc" type="textarea" :rows="2" placeholder="如：达成率=实际/目标×100，得分封顶 100" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
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
import { 
  getIndicatorPage, 
  createIndicator, 
  updateIndicator, 
  deleteIndicator, 
  updateIndicatorStatus, 
  type PerfIndicator 
} from '@/api/perfIndicator'

const loading = ref(false)
const submitLoading = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('')
const dialogMode = ref<'create' | 'edit' | 'view'>('create')
const formRef = ref<FormInstance>()

const tableData = ref<PerfIndicator[]>([])

const searchForm = reactive({
  keyword: '',
  bizCategory: '',
  status: null as number | null
})

const pagination = reactive({
  pageNum: 1,
  pageSize: 10,
  total: 0
})

const form = reactive<PerfIndicator>({
  indicatorCode: '',
  indicatorName: '',
  bizCategory: 'PERFORMANCE',
  scoringType: 'QUANTITATIVE',
  unit: '',
  defaultWeight: 10,
  defaultFactorCode: 'F1',
  dataSource: '',
  scoringDesc: '',
  status: 1
})

const formRules: FormRules = {
  indicatorCode: [{ required: true, message: '请输入指标编码', trigger: 'blur' }],
  indicatorName: [{ required: true, message: '请输入指标名称', trigger: 'blur' }],
  bizCategory: [{ required: true, message: '请选择业务分类', trigger: 'change' }],
  scoringType: [{ required: true, message: '请选择评分类型', trigger: 'change' }],
  defaultFactorCode: [{ required: true, message: '请选择决策因子', trigger: 'change' }]
}

const fetchData = async () => {
  loading.value = true
  try {
    const res = await getIndicatorPage({
      pageNum: pagination.pageNum,
      pageSize: pagination.pageSize,
      keyword: searchForm.keyword || undefined,
      bizCategory: searchForm.bizCategory || undefined,
      status: searchForm.status ?? undefined
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
  searchForm.bizCategory = ''
  searchForm.status = null
  handleSearch()
}

const handleAdd = () => {
  dialogMode.value = 'create'
  dialogTitle.value = '新增指标'
  Object.assign(form, {
    id: undefined,
    indicatorCode: '',
    indicatorName: '',
    bizCategory: 'PERFORMANCE',
    scoringType: 'QUANTITATIVE',
    unit: '',
    defaultWeight: 10,
    defaultFactorCode: 'F1',
    dataSource: '',
    scoringDesc: '',
    status: 1
  })
  dialogVisible.value = true
}

const handleEdit = (row: PerfIndicator) => {
  dialogMode.value = 'edit'
  dialogTitle.value = '编辑指标'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

const handleView = (row: PerfIndicator) => {
  dialogMode.value = 'view'
  dialogTitle.value = '指标详情'
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
      await updateIndicator(form.id, form)
      ElMessage.success('更新成功')
    } else {
      await createIndicator(form)
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

const handleDelete = async (row: PerfIndicator) => {
  try {
    await ElMessageBox.confirm('确定要删除该指标吗？', '提示', { type: 'warning' })
    await deleteIndicator(row.id!)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '删除失败')
    }
  }
}

const handleToggleStatus = async (row: PerfIndicator) => {
  const newStatus = row.status === 1 ? 0 : 1
  const action = newStatus === 1 ? '启用' : '停用'
  try {
    await ElMessageBox.confirm(`确定要${action}该指标吗？`, '提示', { type: 'warning' })
    await updateIndicatorStatus(row.id!, newStatus)
    ElMessage.success(`${action}成功`)
    fetchData()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '操作失败')
    }
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.indicator-container {
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
