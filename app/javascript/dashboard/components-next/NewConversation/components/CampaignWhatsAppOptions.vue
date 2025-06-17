<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  messageTemplates: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['selectedTemplateData']);

const { t } = useI18n();

const formatsToRemove = ['DOCUMENT', 'IMAGE', 'VIDEO'];

const searchQuery = ref('');
const showTemplatesMenu = ref(false);


const whatsAppTemplateMessages = computed(() => {
  const templates = Array.isArray(props.messageTemplates)
    ? props.messageTemplates
    : [];

  return templates
    .filter(template => template?.status?.toLowerCase() === 'approved')
    .filter(template =>
      template?.components?.every(component => !formatsToRemove.includes(component.format))
    )
    .filter(template => {
      const bodyComponent = getTemplateBody(template);
      const placeholders = extractPlaceholders(bodyComponent);
      return placeholders.length === 0;
    });
});

const filteredTemplates = computed(() => {
  return whatsAppTemplateMessages.value.filter(template =>
    template.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const getTemplateBody = template => {
  return template.components.find(component => component.type === 'BODY')?.text || '';
};

const extractPlaceholders = text => {
  const matches = [...text.matchAll(/{{\s*([\w\d]+)\s*}}/g)];
  return matches.map(match => match[1]); // ['1', 'name']
};

const handleTriggerClick = () => {
  searchQuery.value = '';
  showTemplatesMenu.value = !showTemplatesMenu.value;
};

const handleTemplateClick = (template, event) => {
  event.preventDefault();
  event.stopPropagation();

  const bodyText = getTemplateBody(template);
  const placeholders = extractPlaceholders(bodyText);
  
  emit('selectedTemplateData', {
    name: template.name,
    placeholders,
    lang_code: template.language
  });

  showTemplatesMenu.value = false;
};
</script>

<template>
  <div class="relative">
    <Button
      type="button"
      icon="i-ri-whatsapp-line"
      :label="t('COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.LABEL')"
      color="slate"
      size="sm"
      class="!text-xs font-medium"
      @click="handleTriggerClick"
    />

    <div
      v-if="showTemplatesMenu"
      class="absolute top-full mt-1.5 max-h-96 overflow-y-auto left-0 flex flex-col gap-2 p-4 items-center w-[21.875rem] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
    >
      <div class="relative w-full">
        <span class="absolute i-lucide-search size-3.5 top-2 left-3" />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="t('COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.SEARCH_PLACEHOLDER')"
          class="w-full h-8 py-2 pl-10 pr-2 text-sm reset-base outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        />
      </div>

      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="flex flex-col w-full gap-2 p-2 rounded-lg cursor-pointer dark:hover:bg-n-alpha-3 hover:bg-n-alpha-1"
        @click="handleTemplateClick(template, $event)"
      >
        <span class="text-sm text-n-slate-12">{{ template.name }}</span>
        <p class="mb-0 text-xs leading-5 text-n-slate-11 line-clamp-2">
          {{ getTemplateBody(template) }}
        </p>
      </div>

      <template v-if="filteredTemplates.length === 0">
        <p class="w-full pt-2 text-sm text-n-slate-11">
          {{ t('COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_OPTIONS.EMPTY_STATE') }}
        </p>
      </template>
    </div>
  </div>
</template>
