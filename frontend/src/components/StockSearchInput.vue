<template>
  <div class="stock-search-input" ref="containerRef">
    <el-input
      v-model="inputValue"
      :placeholder="placeholder"
      clearable
      :size="size"
      class="stock-input"
      :class="{ 'is-error': error, 'is-focused': isFocused }"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
      @keydown.down.prevent="navigateDown"
      @keydown.up.prevent="navigateUp"
      @keydown.enter.prevent="selectHighlighted"
      @keydown.esc="closeDropdown"
    >
      <template #prefix>
        <el-icon><TrendCharts /></el-icon>
      </template>
      <template #suffix>
        <el-icon v-if="loading" class="is-loading"><Loading /></el-icon>
      </template>
    </el-input>

    <!-- 搜索结果下拉框 -->
    <Transition name="dropdown">
      <div v-if="showDropdown && (searchResults.length > 0 || loading || noResults)" class="search-dropdown">
        <!-- 加载中 -->
        <div v-if="loading" class="dropdown-loading">
          <el-icon class="is-loading"><Loading /></el-icon>
          <span>搜索中...</span>
        </div>

        <!-- 搜索结果 -->
        <div v-else-if="searchResults.length > 0" class="dropdown-results">
          <div
            v-for="(stock, index) in searchResults"
            :key="`${stock.market}-${stock.code}`"
            class="result-item"
            :class="{ 'is-highlighted': highlightedIndex === index }"
            @mouseenter="highlightedIndex = index"
            @mousedown.prevent="selectStock(stock)"
          >
            <div class="stock-main">
              <span class="stock-code">{{ formatStockCode(stock) }}</span>
              <span class="stock-name">{{ stock.name }}</span>
            </div>
            <div class="stock-meta">
              <el-tag size="small" :type="getMarketTagType(stock.market)">
                {{ getMarketLabel(stock.market) }}
              </el-tag>
              <span v-if="stock.industry" class="stock-industry">{{ stock.industry }}</span>
            </div>
          </div>
        </div>

        <!-- 无结果 -->
        <div v-else-if="noResults" class="dropdown-empty">
          <span>未找到相关股票</span>
        </div>
      </div>
    </Transition>

    <!-- 已选中的股票信息 -->
    <div v-if="selectedStock && !isFocused" class="selected-stock-info">
      <el-tag :type="getMarketTagType(selectedStock.market)" size="small">
        {{ getMarketLabel(selectedStock.market) }}
      </el-tag>
      <span class="selected-name">{{ selectedStock.name }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { TrendCharts, Loading } from '@element-plus/icons-vue'
import { searchStocks, type StockInfo } from '@/api/multiMarket'

interface Props {
  modelValue: string
  market?: string
  size?: 'large' | 'default' | 'small'
  placeholder?: string
  error?: boolean
}

interface Emits {
  (e: 'update:modelValue', value: string): void
  (e: 'select', stock: StockInfo): void
  (e: 'marketChange', market: string): void
}

const props = withDefaults(defineProps<Props>(), {
  market: 'A股',
  size: 'large',
  placeholder: '输入代码、名称或拼音（如：000001、平安银行、payh）',
  error: false
})

const emit = defineEmits<Emits>()

const containerRef = ref<HTMLElement>()
const inputValue = ref(props.modelValue)
const searchResults = ref<StockInfo[]>([])
const loading = ref(false)
const isFocused = ref(false)
const showDropdown = ref(false)
const highlightedIndex = ref(-1)
const noResults = ref(false)
const selectedStock = ref<StockInfo | null>(null)

let searchTimer: ReturnType<typeof setTimeout> | null = null

// 市场代码映射
const marketCodeMap: Record<string, string> = {
  'A股': 'CN',
  '美股': 'US',
  '港股': 'HK',
  'CN': 'CN',
  'US': 'US',
  'HK': 'HK'
}

const marketLabelMap: Record<string, string> = {
  'CN': 'A股',
  'HK': '港股',
  'US': '美股',
  'A股': 'A股',
  '港股': '港股',
  '美股': '美股'
}

// 监听外部值变化
watch(() => props.modelValue, (newVal) => {
  if (newVal !== inputValue.value) {
    inputValue.value = newVal
  }
})

// 监听市场变化，清空选中
watch(() => props.market, () => {
  selectedStock.value = null
})

const getMarketCode = (market: string) => {
  return marketCodeMap[market] || 'CN'
}

const getMarketLabel = (market: string) => {
  return marketLabelMap[market] || market
}

const getMarketTagType = (market: string): 'danger' | 'warning' | 'success' | 'info' => {
  const types: Record<string, 'danger' | 'warning' | 'success' | 'info'> = {
    'CN': 'danger',
    'A股': 'danger',
    'HK': 'warning',
    '港股': 'warning',
    'US': 'success',
    '美股': 'success'
  }
  return types[market] || 'info'
}

const formatStockCode = (stock: StockInfo) => {
  if (stock.market === 'HK') {
    return stock.code.padStart(5, '0')
  }
  return stock.code
}

const handleInput = () => {
  emit('update:modelValue', inputValue.value)
  selectedStock.value = null

  if (searchTimer) {
    clearTimeout(searchTimer)
  }

  const query = inputValue.value.trim()
  if (!query) {
    searchResults.value = []
    noResults.value = false
    showDropdown.value = false
    return
  }

  // 防抖搜索
  searchTimer = setTimeout(async () => {
    await performSearch(query)
  }, 300)
}

const performSearch = async (query: string) => {
  if (!query) return

  loading.value = true
  showDropdown.value = true
  noResults.value = false
  highlightedIndex.value = -1

  try {
    const marketCode = getMarketCode(props.market)
    const response = await searchStocks(marketCode, query, 10)
    searchResults.value = response.data?.stocks || []
    noResults.value = searchResults.value.length === 0
  } catch (error) {
    console.error('搜索股票失败:', error)
    searchResults.value = []
    noResults.value = true
  } finally {
    loading.value = false
  }
}

const handleFocus = () => {
  isFocused.value = true
  if (inputValue.value.trim() && searchResults.value.length > 0) {
    showDropdown.value = true
  }
}

const handleBlur = () => {
  // 延迟关闭，允许点击下拉项
  setTimeout(() => {
    isFocused.value = false
    showDropdown.value = false
  }, 200)
}

const closeDropdown = () => {
  showDropdown.value = false
  highlightedIndex.value = -1
}

const navigateDown = () => {
  if (!showDropdown.value || searchResults.value.length === 0) return
  highlightedIndex.value = (highlightedIndex.value + 1) % searchResults.value.length
}

const navigateUp = () => {
  if (!showDropdown.value || searchResults.value.length === 0) return
  highlightedIndex.value = highlightedIndex.value <= 0
    ? searchResults.value.length - 1
    : highlightedIndex.value - 1
}

const selectHighlighted = () => {
  if (highlightedIndex.value >= 0 && highlightedIndex.value < searchResults.value.length) {
    selectStock(searchResults.value[highlightedIndex.value])
  }
}

const selectStock = (stock: StockInfo) => {
  selectedStock.value = stock
  inputValue.value = stock.code
  emit('update:modelValue', stock.code)
  emit('select', stock)

  // 自动更新市场类型
  const marketLabel = getMarketLabel(stock.market)
  if (marketLabel !== props.market) {
    emit('marketChange', marketLabel)
  }

  closeDropdown()
}

// 点击外部关闭下拉框
const handleClickOutside = (event: MouseEvent) => {
  if (containerRef.value && !containerRef.value.contains(event.target as Node)) {
    closeDropdown()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
  if (searchTimer) {
    clearTimeout(searchTimer)
  }
})
</script>

<style scoped lang="scss">
.stock-search-input {
  position: relative;
  width: 100%;
}

.stock-input {
  :deep(.el-input__inner) {
    font-weight: 600;
    text-transform: uppercase;
  }

  &.is-error {
    :deep(.el-input__wrapper) {
      box-shadow: 0 0 0 1px #f56c6c inset;
    }
  }

  &.is-focused {
    :deep(.el-input__wrapper) {
      box-shadow: 0 0 0 1px var(--el-color-primary) inset;
    }
  }
}

.search-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  z-index: 2000;
  margin-top: 4px;
  background: var(--el-bg-color);
  border: 1px solid var(--el-border-color);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  max-height: 320px;
  overflow-y: auto;
}

.dropdown-loading,
.dropdown-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 16px;
  color: var(--el-text-color-secondary);
  font-size: 14px;
}

.dropdown-results {
  padding: 4px 0;
}

.result-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 10px 12px;
  cursor: pointer;
  transition: background-color 0.15s;

  &:hover,
  &.is-highlighted {
    background-color: var(--el-fill-color-light);
  }

  &.is-highlighted {
    background-color: var(--el-color-primary-light-9);
  }
}

.stock-main {
  display: flex;
  align-items: center;
  gap: 8px;
}

.stock-code {
  font-weight: 600;
  font-size: 14px;
  color: var(--el-text-color-primary);
  min-width: 60px;
}

.stock-name {
  font-size: 14px;
  color: var(--el-text-color-regular);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stock-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: 68px;
}

.stock-industry {
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.selected-stock-info {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  padding: 4px 0;

  .selected-name {
    font-size: 13px;
    color: var(--el-text-color-regular);
  }
}

/* 下拉动画 */
.dropdown-enter-active,
.dropdown-leave-active {
  transition: all 0.2s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* 移动端优化 */
@media (max-width: 767px) {
  .search-dropdown {
    max-height: 260px;
    border-radius: 10px;
  }

  .result-item {
    padding: 12px;
  }

  .stock-code {
    font-size: 15px;
  }

  .stock-name {
    font-size: 14px;
  }

  .stock-meta {
    margin-left: 0;
    margin-top: 4px;
  }

  .selected-stock-info {
    flex-wrap: wrap;
  }
}
</style>
