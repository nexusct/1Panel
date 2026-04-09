<template>
    <div>
        <LayoutContent :title="$t('menu.toolboxInstallers')" v-loading="refreshing">
            <template #toolbar>
                <el-button @click="refreshAll" :loading="refreshing">
                    {{ $t('commons.button.refresh') }}
                </el-button>
            </template>
            <template #main>
                <el-row :gutter="20" class="tool-grid mt-4">
                    <el-col v-for="tool in tools" :key="tool.key" :xs="24" :sm="12" :md="8" :lg="6">
                        <el-card class="tool-card mb-5" shadow="hover">
                            <template #header>
                                <div class="tool-header">
                                    <span class="tool-name">{{ tool.name }}</span>
                                    <el-tag :type="tool.status?.installed ? 'success' : 'info'" size="small">
                                        {{
                                            tool.status?.installed
                                                ? $t('toolbox.installers.installed')
                                                : $t('toolbox.installers.notInstalled')
                                        }}
                                        <span v-if="tool.status?.version">({{ tool.status.version }})</span>
                                    </el-tag>
                                </div>
                            </template>
                            <p class="tool-desc">{{ tool.description }}</p>
                            <el-tag type="warning" size="small" class="tool-category">{{ tool.category }}</el-tag>
                            <div class="tool-actions mt-3 flex gap-2">
                                <el-button
                                    type="primary"
                                    size="small"
                                    :loading="tool.installing"
                                    :disabled="tool.status?.installed || tool.installing"
                                    @click="onInstall(tool)"
                                >
                                    {{ $t('toolbox.installers.install') }}
                                </el-button>
                                <el-button size="small" v-if="tool.lastOutput" @click="openLog(tool)">
                                    {{ $t('toolbox.installers.viewLog') }}
                                </el-button>
                            </div>
                        </el-card>
                    </el-col>
                </el-row>
            </template>
        </LayoutContent>

        <el-drawer v-model="logDrawer.visible" :title="logDrawer.title" size="50%" direction="rtl">
            <pre class="log-output">{{ logDrawer.output }}</pre>
            <p v-if="logDrawer.error" class="log-error">{{ logDrawer.error }}</p>
        </el-drawer>
    </div>
</template>

<script lang="ts" setup>
import { onMounted, reactive, ref } from 'vue';
import { installTool, getToolInstallStatus, ToolInstallStatus } from '@/api/modules/toolbox';
import { MsgSuccess, MsgError } from '@/utils/message';
import i18n from '@/lang';

interface ToolDef {
    key: string;
    name: string;
    description: string;
    category: string;
    status?: ToolInstallStatus;
    installing: boolean;
    lastOutput?: string;
    lastError?: string;
}

const refreshing = ref(false);

const tools = reactive<ToolDef[]>([
    {
        key: 'claude-code',
        name: 'Claude Code',
        description: i18n.global.t('toolbox.installers.claudeCodeDesc'),
        category: 'AI CLI',
        installing: false,
    },
    {
        key: 'codex-cli',
        name: 'Codex CLI',
        description: i18n.global.t('toolbox.installers.codexCliDesc'),
        category: 'AI CLI',
        installing: false,
    },
    {
        key: 'odoo',
        name: 'Odoo ERP',
        description: i18n.global.t('toolbox.installers.odooDesc'),
        category: 'ERP',
        installing: false,
    },
    {
        key: 'shopify',
        name: 'Shopify CLI',
        description: i18n.global.t('toolbox.installers.shopifyDesc'),
        category: 'E-Commerce CLI',
        installing: false,
    },
    {
        key: 'contentful',
        name: 'Contentful CLI',
        description: i18n.global.t('toolbox.installers.contentfulDesc'),
        category: 'CMS CLI',
        installing: false,
    },
    {
        key: 'strapi',
        name: 'Strapi CMS',
        description: i18n.global.t('toolbox.installers.strapiDesc'),
        category: 'Headless CMS',
        installing: false,
    },
    {
        key: 'react-bricks',
        name: 'React Bricks CMS',
        description: i18n.global.t('toolbox.installers.reactBricksDesc'),
        category: 'Visual CMS',
        installing: false,
    },
]);

const logDrawer = reactive({
    visible: false,
    title: '',
    output: '',
    error: '',
});

const loadStatus = async (tool: ToolDef) => {
    try {
        const res = await getToolInstallStatus(tool.key);
        tool.status = res.data;
    } catch {
        tool.status = { installed: false };
    }
};

const refreshAll = async () => {
    refreshing.value = true;
    await Promise.all(tools.map((t) => loadStatus(t)));
    refreshing.value = false;
};

const onInstall = async (tool: ToolDef) => {
    tool.installing = true;
    tool.lastOutput = undefined;
    tool.lastError = undefined;
    try {
        const res = await installTool({ tool: tool.key });
        tool.lastOutput = res.data.output;
        tool.lastError = res.data.error;
        if (res.data.error) {
            MsgError(`${tool.name}: ${res.data.error}`);
        } else {
            MsgSuccess(`${tool.name} ${i18n.global.t('toolbox.installers.installSuccess')}`);
            await loadStatus(tool);
        }
    } catch (e: any) {
        tool.lastError = e?.message || String(e);
        MsgError(`${tool.name}: ${tool.lastError}`);
    } finally {
        tool.installing = false;
    }
};

const openLog = (tool: ToolDef) => {
    logDrawer.title = tool.name + ' — ' + i18n.global.t('toolbox.installers.installLog');
    logDrawer.output = tool.lastOutput || '';
    logDrawer.error = tool.lastError || '';
    logDrawer.visible = true;
};

onMounted(refreshAll);
</script>

<style scoped>
.tool-card {
    height: 100%;
}
.tool-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.tool-name {
    font-weight: 600;
    font-size: 15px;
}
.tool-desc {
    color: #666;
    font-size: 13px;
    min-height: 44px;
    margin: 8px 0;
}
.log-output {
    background: #1e1e1e;
    color: #d4d4d4;
    padding: 16px;
    border-radius: 6px;
    font-size: 12px;
    white-space: pre-wrap;
    max-height: 70vh;
    overflow-y: auto;
}
.log-error {
    color: #f56c6c;
    font-size: 13px;
    margin-top: 8px;
}
</style>
