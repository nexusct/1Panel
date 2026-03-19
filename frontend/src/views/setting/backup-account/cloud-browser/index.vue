<template>
    <DrawerPro v-model="open" :header="$t('setting.cloudFileBrowser')" size="large" @close="handleClose">
        <el-form ref="formRef" :model="form" label-position="top">
            <el-alert type="info" :closable="false" class="mb-4">
                <template #title>{{ $t('setting.cloudFileBrowserHelper') }}</template>
            </el-alert>
            <el-form-item :label="$t('setting.cloudFilePath')" prop="currentPath">
                <el-input v-model="form.currentPath" @keyup.enter="loadFiles">
                    <template #append>
                        <el-button @click="loadFiles" :loading="loadingFiles">
                            {{ $t('commons.button.search') }}
                        </el-button>
                    </template>
                </el-input>
            </el-form-item>
        </el-form>

        <el-table :data="files" v-loading="loadingFiles" stripe>
            <el-table-column :label="$t('commons.table.name')" prop="name" show-overflow-tooltip />
            <el-table-column :label="$t('commons.table.operate')" width="160" fixed>
                <template #default="{ row }">
                    <el-button
                        type="primary"
                        link
                        @click="openSyncDialog(row)"
                        :disabled="row.isDir"
                    >
                        {{ $t('setting.syncToLocal') }}
                    </el-button>
                </template>
            </el-table-column>
        </el-table>

        <el-dialog v-model="syncDialogVisible" :title="$t('setting.syncToLocal')" width="500px">
            <el-form :model="syncForm" label-position="top">
                <el-form-item :label="$t('setting.cloudFilePath')">
                    <el-input v-model="syncForm.srcPath" disabled />
                </el-form-item>
                <el-form-item :label="$t('setting.syncToLocalPath')" required>
                    <el-input v-model="syncForm.dstPath" placeholder="/opt/downloads" />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="syncDialogVisible = false">{{ $t('commons.button.cancel') }}</el-button>
                <el-button type="primary" :loading="syncing" @click="doSync">
                    {{ $t('setting.syncToLocal') }}
                </el-button>
            </template>
        </el-dialog>
    </DrawerPro>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { listCloudFiles, syncCloudFileToLocal } from '@/api/modules/backup';
import { MsgSuccess } from '@/utils/message';
import i18n from '@/lang';
import { Backup } from '@/api/interface/backup';

const open = ref(false);
const loadingFiles = ref(false);
const syncing = ref(false);
const syncDialogVisible = ref(false);
const files = ref<Backup.CloudFileInfo[]>([]);
const accountID = ref(0);

const form = reactive({
    currentPath: '',
});

const syncForm = reactive({
    srcPath: '',
    dstPath: '',
});

const handleClose = () => {
    open.value = false;
    files.value = [];
    form.currentPath = '';
};

const loadFiles = async () => {
    loadingFiles.value = true;
    try {
        const res = await listCloudFiles({ accountID: accountID.value, path: form.currentPath });
        files.value = res.data || [];
    } catch {
        files.value = [];
    } finally {
        loadingFiles.value = false;
    }
};

const openSyncDialog = (row: Backup.CloudFileInfo) => {
    const cloudPath = form.currentPath ? form.currentPath.replace(/\/$/, '') + '/' + row.name : row.name;
    syncForm.srcPath = cloudPath;
    syncForm.dstPath = '';
    syncDialogVisible.value = true;
};

const doSync = async () => {
    if (!syncForm.dstPath) {
        return;
    }
    syncing.value = true;
    try {
        await syncCloudFileToLocal({
            accountID: accountID.value,
            srcPath: syncForm.srcPath,
            dstPath: syncForm.dstPath,
        });
        MsgSuccess(i18n.global.t('setting.syncToLocalSuccess'));
        syncDialogVisible.value = false;
    } finally {
        syncing.value = false;
    }
};

const openBrowser = (id: number) => {
    accountID.value = id;
    open.value = true;
    files.value = [];
    form.currentPath = '';
    loadFiles();
};

defineExpose({ openBrowser });
</script>
