# Journal des décisions — IFSB-DataHub

| Date | Décision | Justification |
|---|---|---|
| 2026-07-19 | Téléchargement des 4 segments PSIFIs depuis data.ifsb.org (extraits horodatés dans les noms de fichiers d'origine) | Portail officiel, plus à jour que la page statique ifsb.org/data-metadata (vérifié) |
| 2026-07-19 | Clé d'harmonisation du hub : iso3 x year x quarter ; tableau maître en format long | Ajout de sources futures = lignes, pas colonnes |
| 2026-07-19 | Turquie exclue du panel trimestriel takaful (robustesse annuelle seulement) | Valeurs uniquement en Q4 ; contributions brutes manquantes aussi dans le fichier "Takaful Windows" (vérifié : 46/46/36 points, GWC = "…") |
| 2026-07-19 | Échantillon de référence papier takaful-incertitude : 7 pays x 16 trimestres (2019Q1–2022Q4) ; BRN et ARE disponibles jusqu'à 2023Q4 | Dernière dissémination takaful de l'IFSB ; le segment bancaire va, lui, jusqu'à 2025Q4 |
| 2026-07-19 | Fichiers bruts figés dans raw/ifsb/ (jamais modifiés) ; tout nettoyage passe par scripts/ | Reproductibilité ; l'IFSB révise ses chiffres rétroactivement |
| 2026-07-19 | WUI intégré (segment "uncert" : WUI_RAW, WUI_MA3 par pays ; WUI_GLOBAL iso3=WLD). BHR et BRN absents des 143 pays du WUI | Spécification principale sur 5 pays (JOR, MYS, NGA, SAU, ARE) avec WUI pays ; spécification B à 7 pays avec WUI_GLOBAL (sans effets fixes temporels) — décision à confirmer |
| 2026-07-19 | Panel de modélisation extrait (panel_takaful_uncert) : VD gwc_gen/gwc_fam en USD mn ; contrôles opérateurs, equity/assets, opex, invest income, rétention ; wui_ma3 principal | Spec A = 84 obs exploitables ; contributions en USD pour comparabilité inter-pays (locale en repli) |
