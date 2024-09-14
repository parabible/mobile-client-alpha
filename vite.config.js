import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      include: ["**/*.res.mjs"],
    }),
    VitePWA({
      registerType: "autoUpdate",
      manifest: {
        name: "Parabible Mobile",
        short_name: "Parabible",
        description: "Unlock the original languages with morphologically parsed and tagged Greek, Hebrew and Aramaic for searching and studying the Bible (both Old and New Testament)."
      }
    }),
  ],
});
