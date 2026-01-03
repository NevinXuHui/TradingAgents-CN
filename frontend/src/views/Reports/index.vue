<template>
  <div class="reports">
    <!-- 页面标题 -->
    <div class="page-header">
      <h1 class="page-title">
        <el-icon><Document /></el-icon>
        分析报告
      </h1>
      <p class="page-description">
        查看和管理股票分析报告，支持多种格式导出
      </p>
    </div>

    <!-- 筛选和操作栏 -->
    <el-card class="filter-card" shadow="never">
      <el-row :gutter="12" align="middle">
        <el-col :xs="24" :sm="12" :md="6" :lg="6">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索股票代码或名称"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>

        <el-col :xs="12" :sm="12" :md="4" :lg="4">
          <el-select v-model="marketFilter" placeholder="市场筛选" clearable @change="handleMarketChange">
            <el-option label="A股" value="A股" />
            <el-option label="港股" value="港股" />
            <el-option label="美股" value="美股" />
          </el-select>
        </el-col>

        <el-col :xs="12" :sm="12" :md="6" :lg="6" class="date-picker-col">
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始"
            end-placeholder="结束"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            @change="handleDateChange"
          />
        </el-col>

        <el-col :xs="24" :sm="12" :md="8" :lg="8">
          <div class="action-buttons">
            <el-button @click="exportSelected" :disabled="selectedReports.length === 0" class="mobile-hide-text">
              <el-icon><Download /></el-icon>
              <span class="btn-text">批量导出</span>
            </el-button>
            <el-button @click="refreshReports" class="mobile-hide-text">
              <el-icon><Refresh /></el-icon>
              <span class="btn-text">刷新</span>
            </el-button>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 报告列表 - 桌面端表格 -->
    <el-card class="reports-list-card desktop-table" shadow="never">
      <el-table
        :data="filteredReports"
        @selection-change="handleSelectionChange"
        v-loading="loading"
        style="width: 100%"
      >
        <el-table-column type="selection" width="55" />

        <el-table-column prop="title" label="报告标题" min-width="200">
          <template #default="{ row }">
            <div class="report-title">
              <el-link type="primary" @click="viewReport(row)">
                {{ row.title }}
              </el-link>
              <div class="report-subtitle">
                {{ row.stock_code }} - {{ row.stock_name }}
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="type" label="报告类型" width="120">
          <template #default="{ row }">
            <el-tag :type="getTypeColor(row.type)">
              {{ getTypeText(row.type) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="format" label="格式" width="100">
          <template #default="{ row }">
            <el-tag size="small" effect="plain">
              {{ row.format.toUpperCase() }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="model_info" label="分析模型" width="180">
          <template #default="{ row }">
            <el-tag v-if="row.model_info && row.model_info !== 'Unknown'" type="info" size="small">
              {{ row.model_info }}
            </el-tag>
            <span v-else class="text-gray">-</span>
          </template>
        </el-table-column>

        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatTime(row.created_at) }}
          </template>
        </el-table-column>

        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button type="text" size="small" @click="viewReport(row)">
              查看
            </el-button>
            <el-dropdown
              v-if="row.status === 'completed'"
              trigger="click"
              @command="(format) => downloadReport(row, format)"
            >
              <el-button type="text" size="small">
                下载 <el-icon class="el-icon--right"><arrow-down /></el-icon>
              </el-button>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="markdown">
                    <el-icon><document /></el-icon> Markdown
                  </el-dropdown-item>
                  <el-dropdown-item command="docx">
                    <el-icon><document /></el-icon> Word 文档
                  </el-dropdown-item>
                  <el-dropdown-item command="pdf">
                    <el-icon><document /></el-icon> PDF
                  </el-dropdown-item>
                  <el-dropdown-item command="json" divided>
                    <el-icon><document /></el-icon> JSON (原始数据)
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
            <el-button
              type="text"
              size="small"
              @click="deleteReport(row)"
              style="color: var(--el-color-danger)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[20, 50, 100]"
          :total="totalReports"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 报告列表 - 移动端卡片 -->
    <div class="mobile-card-list" v-loading="loading">
      <div v-if="filteredReports.length === 0 && !loading" class="empty-state">
        <el-empty description="暂无报告数据" />
      </div>

      <div
        v-for="report in filteredReports"
        :key="report.id"
        class="report-card"
        @click="viewReport(report)"
      >
        <div class="card-header">
          <div class="card-title">{{ report.title }}</div>
          <el-tag :type="getStatusType(report.status)" size="small">
            {{ getStatusText(report.status) }}
          </el-tag>
        </div>

        <div class="card-info">
          <span class="stock-info">{{ report.stock_code }} - {{ report.stock_name }}</span>
        </div>

        <div class="card-meta">
          <div class="meta-left">
            <el-tag :type="getTypeColor(report.type)" size="small">
              {{ getTypeText(report.type) }}
            </el-tag>
            <el-tag v-if="report.model_info && report.model_info !== 'Unknown'" type="info" size="small">
              {{ report.model_info }}
            </el-tag>
          </div>
          <span class="time">{{ formatTime(report.created_at) }}</span>
        </div>

        <div class="card-actions" @click.stop>
          <el-button size="small" type="primary" @click="viewReport(report)">
            <el-icon><View /></el-icon>
            查看
          </el-button>
          <el-dropdown
            v-if="report.status === 'completed'"
            trigger="click"
            @command="(format) => downloadReport(report, format)"
          >
            <el-button size="small">
              <el-icon><Download /></el-icon>
              下载
            </el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="markdown">Markdown</el-dropdown-item>
                <el-dropdown-item command="docx">Word</el-dropdown-item>
                <el-dropdown-item command="pdf">PDF</el-dropdown-item>
                <el-dropdown-item command="json" divided>JSON</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-button size="small" type="danger" plain @click="deleteReport(report)">
            <el-icon><Delete /></el-icon>
          </el-button>
        </div>
      </div>

      <!-- 移动端分页 -->
      <div class="mobile-pagination" v-if="totalReports > 0">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :total="totalReports"
          layout="prev, pager, next"
          :pager-count="5"
          small
          @current-change="handleCurrentChange"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Document,
  Search,
  Download,
  Refresh,
  ArrowDown,
  View,
  Delete
} from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'

// 使用路由和认证store
const router = useRouter()
const authStore = useAuthStore()

// 响应式数据
const loading = ref(false)
const searchKeyword = ref('')
const marketFilter = ref('')
const dateRange = ref<[string, string] | null>(null)
const selectedReports = ref([])
const currentPage = ref(1)
const pageSize = ref(20)
const totalReports = ref(0)

const reports = ref([])

// 计算属性
const filteredReports = computed(() => {
  // 现在数据直接从API获取，不需要前端筛选
  return reports.value
})

// API调用函数
const fetchReports = async () => {
  loading.value = true
  try {
    const params = new URLSearchParams({
      page: currentPage.value.toString(),
      page_size: pageSize.value.toString()
    })

    if (searchKeyword.value) {
      params.append('search_keyword', searchKeyword.value)
    }
    if (marketFilter.value) {
      params.append('market_filter', marketFilter.value)
    }
    if (dateRange.value) {
      params.append('start_date', dateRange.value[0])
      params.append('end_date', dateRange.value[1])
    }

    const response = await fetch(`/api/reports/list?${params}`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }

    const result = await response.json()

    if (result.success) {
      reports.value = result.data.reports
      totalReports.value = result.data.total
    } else {
      throw new Error(result.message || '获取报告列表失败')
    }
  } catch (error) {
    console.error('获取报告列表失败:', error)
    ElMessage.error('获取报告列表失败')
  } finally {
    loading.value = false
  }
}

// 方法
const handleSearch = () => {
  currentPage.value = 1
  fetchReports()
}

const handleDateChange = () => {
  currentPage.value = 1
  fetchReports()
}

const handleMarketChange = () => {
  currentPage.value = 1
  fetchReports()
}

const handleSelectionChange = (selection: any[]) => {
  selectedReports.value = selection
}

const viewReport = (report: any) => {
  // 跳转到报告详情页面
  router.push(`/reports/view/${report.id}`)
}

const downloadReport = async (report: any, format: string = 'markdown') => {
  try {
    // 显示加载提示
    const loadingMsg = ElMessage({
      message: `正在生成${getFormatName(format)}格式报告...`,
      type: 'info',
      duration: 0
    })

    const response = await fetch(`/api/reports/${report.id}/download?format=${format}`, {
      headers: {
        'Authorization': `Bearer ${authStore.token}`
      }
    })

    loadingMsg.close()

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(errorText || `HTTP ${response.status}`)
    }

    const blob = await response.blob()
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url

    // 根据格式设置文件扩展名
    const ext = getFileExtension(format)
    a.download = `${report.stock_code}_分析报告_${report.analysis_date}.${ext}`

    document.body.appendChild(a)
    a.click()
    window.URL.revokeObjectURL(url)
    document.body.removeChild(a)

    ElMessage.success(`${getFormatName(format)}报告下载成功`)
  } catch (error: any) {
    console.error('下载报告失败:', error)

    // 显示详细错误信息
    if (error.message && error.message.includes('pandoc')) {
      ElMessage.error({
        message: 'PDF/Word 导出需要安装 pandoc 工具',
        duration: 5000
      })
    } else {
      ElMessage.error(`下载报告失败: ${error.message || '未知错误'}`)
    }
  }
}

// 辅助函数：获取格式名称
const getFormatName = (format: string): string => {
  const names: Record<string, string> = {
    'markdown': 'Markdown',
    'docx': 'Word',
    'pdf': 'PDF',
    'json': 'JSON'
  }
  return names[format] || format
}

// 辅助函数：获取文件扩展名
const getFileExtension = (format: string): string => {
  const extensions: Record<string, string> = {
    'markdown': 'md',
    'docx': 'docx',
    'pdf': 'pdf',
    'json': 'json'
  }
  return extensions[format] || 'txt'
}

const deleteReport = async (report: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除报告 "${report.title}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    // 调用删除API
    const response = await fetch(`/api/reports/${report.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${authStore.token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }

    const result = await response.json()

    if (result.success) {
      ElMessage.success('报告已删除')
      refreshReports()
    } else {
      throw new Error(result.message || '删除失败')
    }
  } catch (error) {
    if (error.message !== 'cancel') {
      console.error('删除报告失败:', error)
      ElMessage.error('删除报告失败')
    }
  }
}

const exportSelected = () => {
  ElMessage.info('批量导出功能开发中...')
}

const refreshReports = () => {
  fetchReports()
}

const getTypeColor = (type: string) => {
  const colorMap: Record<string, string> = {
    single: 'primary',
    batch: 'success',
    portfolio: 'warning'
  }
  return colorMap[type] || 'info'
}

const getTypeText = (type: string) => {
  const textMap: Record<string, string> = {
    single: '单股分析',
    batch: '批量分析',
    portfolio: '投资组合'
  }
  return textMap[type] || type
}

const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    completed: 'success',
    processing: 'warning',
    failed: 'danger'
  }
  return statusMap[status] || 'info'
}

const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    completed: '已完成',
    processing: '生成中',
    failed: '失败'
  }
  return statusMap[status] || status
}

import { formatDateTime } from '@/utils/datetime'

const formatTime = (time: string) => {
  return formatDateTime(time)
}

const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  fetchReports()
}

const handleCurrentChange = (page: number) => {
  currentPage.value = page
  fetchReports()
}

// 生命周期
onMounted(() => {
  fetchReports()
})
</script>

<style lang="scss" scoped>
.reports {
  .page-header {
    margin-bottom: 24px;

    .page-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 24px;
      font-weight: 600;
      color: var(--el-text-color-primary);
      margin: 0 0 8px 0;
    }

    .page-description {
      color: var(--el-text-color-regular);
      margin: 0;
    }
  }

  .filter-card {
    margin-bottom: 24px;

    .action-buttons {
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }

    .date-picker-col {
      :deep(.el-date-editor) {
        width: 100%;
      }
    }
  }

  .reports-list-card {
    .report-title {
      .report-subtitle {
        font-size: 12px;
        color: var(--el-text-color-placeholder);
        margin-top: 2px;
      }
    }

    .pagination-wrapper {
      display: flex;
      justify-content: center;
      margin-top: 24px;
    }
  }

  // 移动端卡片列表 - 默认隐藏
  .mobile-card-list {
    display: none;
  }
}

// ==================== 移动端响应式样式 ====================
@media (max-width: 767px) {
  .reports {
    // 页面标题移动端适配
    .page-header {
      margin-bottom: 16px;

      .page-title {
        font-size: 18px;
      }

      .page-description {
        font-size: 13px;
      }
    }

    // 筛选卡片移动端适配
    .filter-card {
      margin-bottom: 16px;

      :deep(.el-card__body) {
        padding: 12px;
      }

      :deep(.el-row) {
        row-gap: 12px;
      }

      :deep(.el-col) {
        margin-bottom: 0;
      }

      :deep(.el-select),
      :deep(.el-input) {
        width: 100%;
      }

      :deep(.el-date-editor) {
        width: 100% !important;

        .el-range-separator {
          padding: 0 4px;
        }

        .el-range-input {
          width: 40%;
        }
      }

      .action-buttons {
        justify-content: flex-start;
        margin-top: 4px;

        .el-button {
          flex: 1;

          .btn-text {
            display: none;
          }
        }
      }
    }

    // 隐藏桌面端表格
    .desktop-table {
      display: none;
    }

    // 显示移动端卡片列表
    .mobile-card-list {
      display: block;

      .empty-state {
        padding: 40px 20px;
        text-align: center;
      }

      .report-card {
        background: var(--el-bg-color);
        border: 1px solid var(--el-border-color-light);
        border-radius: 12px;
        padding: 16px;
        margin-bottom: 12px;
        transition: all 0.2s ease;

        &:active {
          background: var(--el-fill-color-light);
        }

        .card-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 8px;

          .card-title {
            font-size: 15px;
            font-weight: 600;
            color: var(--el-text-color-primary);
            flex: 1;
            margin-right: 8px;
            line-height: 1.4;
          }
        }

        .card-info {
          margin-bottom: 10px;

          .stock-info {
            font-size: 13px;
            color: var(--el-text-color-regular);
          }
        }

        .card-meta {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 12px;
          flex-wrap: wrap;
          gap: 8px;

          .meta-left {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
          }

          .time {
            font-size: 12px;
            color: var(--el-text-color-placeholder);
          }
        }

        .card-actions {
          display: flex;
          gap: 8px;
          padding-top: 12px;
          border-top: 1px solid var(--el-border-color-lighter);

          .el-button {
            flex: 1;
            margin: 0;
          }
        }
      }

      .mobile-pagination {
        display: flex;
        justify-content: center;
        padding: 16px 0;

        :deep(.el-pagination) {
          .el-pager li {
            min-width: 28px;
            height: 28px;
            line-height: 28px;
          }
        }
      }
    }
  }
}

// ==================== 小屏手机适配 (< 375px) ====================
@media (max-width: 374px) {
  .reports {
    .page-header {
      .page-title {
        font-size: 16px;
      }
    }

    .filter-card {
      .action-buttons {
        .el-button {
          padding: 8px 12px;
        }
      }
    }

    .mobile-card-list {
      .report-card {
        padding: 12px;

        .card-title {
          font-size: 14px;
        }

        .card-actions {
          flex-wrap: wrap;

          .el-button {
            min-width: calc(50% - 4px);
            flex: none;
          }
        }
      }
    }
  }
}

// ==================== 平板端适配 (768px - 991px) ====================
@media (min-width: 768px) and (max-width: 991px) {
  .reports {
    .filter-card {
      :deep(.el-row) {
        row-gap: 12px;
      }
    }

    .reports-list-card {
      :deep(.el-table) {
        font-size: 13px;

        // 隐藏部分列
        .el-table__cell:nth-child(4), // 格式列
        .el-table__cell:nth-child(6) { // 模型列
          display: none;
        }
      }
    }
  }
}
</style>
