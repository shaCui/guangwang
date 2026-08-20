<script setup lang="ts" generic="T extends any, O extends any">
defineOptions({
  name: 'IndexPage',
})
</script>

<template>
  <div relative min-h-100vh>
    <img h-full w-full src="../assets/bg.webp" alt="">

    <div class="email" absolute bottom-10 w-full flex justify-center>
      <a href="mailto:ze123@gmail.com" rd-2 bg-black p-2 p-x-5 text-8 color-white style="text-decoration: none">
        ze123@gmail.com
      </a>
    </div>
  </div>
</template>
