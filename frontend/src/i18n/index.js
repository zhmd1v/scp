import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";

import en from "./en.json";
import ru from "./ru.json";
import kz from "./kz.json";

i18n
    .use(LanguageDetector)
    .use(initReactI18next)
    .init({
        resources: {
            en: { translation: en },
            ru: { translation: ru },
            kz: { translation: kz }
        },
        fallbackLng: "en",
        interpolation: { escapeValue: false }
    });

export default i18n;