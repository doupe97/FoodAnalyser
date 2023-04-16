# install packages
# for reading excel file, source: https://cran.r-project.org/web/packages/readxl/readxl.pdf
install.packages("readxl")
# for calculating / plotting the spearman correlation matrices, source: https://cran.r-project.org/web/packages/sjPlot/sjPlot.pdf
install.packages("sjPlot")
# for calculation the partial correlations, source: https://cran.r-project.org/web/packages/ppcor/ppcor.pdf
install.packages("ppcor")

# load packages
library(readxl)
library(sjPlot)
library(ppcor)

# remove existing environment variables
rm(list = ls())

# import measurement data
src_xlsx <- 'messergebnisse.xlsx'
data_apple <- subset(read_excel(src_xlsx, sheet = 9), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))
data_banana <- subset(read_excel(src_xlsx, sheet = 10), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))
data_pear <- subset(read_excel(src_xlsx, sheet = 11), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))
data_broccoli <- subset(read_excel(src_xlsx, sheet = 12), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))
data_hokkaido <- subset(read_excel(src_xlsx, sheet = 13), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))
data_kiwi <- subset(read_excel(src_xlsx, sheet = 14), select = c(BILDANZAHL, RANG_KONFIG_PROFIL, MZ_MEDIAN, RMA_V_BETRAG))

# calculate spearman correlation matrices (unbereinigt)
cor_matrix_apple <- tab_corr(data_apple, corr.method = c("spearman"), p.numeric = TRUE, title = "Apfel")
cor_matrix_banana <- tab_corr(data_banana, corr.method = c("spearman"), p.numeric = TRUE, title = "Banane")
cor_matrix_pear <- tab_corr(data_pear, corr.method = c("spearman"), p.numeric = TRUE, title = "Birne")
cor_matrix_broccoli <- tab_corr(data_broccoli, corr.method = c("spearman"), p.numeric = TRUE, title = "Brokkoli")
cor_matrix_hokkaido <- tab_corr(data_hokkaido, corr.method = c("spearman"), p.numeric = TRUE, title = "Hokkaido")
cor_matrix_kiwi <- tab_corr(data_kiwi, corr.method = c("spearman"), p.numeric = TRUE, title = "Kiwi")

# calculate partial correlations and significance p-values (bereinigt)
# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_apple <- pcor.test(data_apple$RMA_V_BETRAG, data_apple$BILDANZAHL, data_apple$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_apple <- pcor.test(data_apple$RMA_V_BETRAG, data_apple$RANG_KONFIG_PROFIL, data_apple$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_apple <- pcor.test(data_apple$MZ_MEDIAN, data_apple$BILDANZAHL, data_apple$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_apple <- pcor.test(data_apple$MZ_MEDIAN, data_apple$RANG_KONFIG_PROFIL, data_apple$BILDANZAHL, method = c("spearman"))

# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_banana <- pcor.test(data_banana$RMA_V_BETRAG, data_banana$BILDANZAHL, data_banana$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_banana <- pcor.test(data_banana$RMA_V_BETRAG, data_banana$RANG_KONFIG_PROFIL, data_banana$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_banana <- pcor.test(data_banana$MZ_MEDIAN, data_banana$BILDANZAHL, data_banana$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_banana <- pcor.test(data_banana$MZ_MEDIAN, data_banana$RANG_KONFIG_PROFIL, data_banana$BILDANZAHL, method = c("spearman"))

# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_pear <- pcor.test(data_pear$RMA_V_BETRAG, data_pear$BILDANZAHL, data_pear$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_pear <- pcor.test(data_pear$RMA_V_BETRAG, data_pear$RANG_KONFIG_PROFIL, data_pear$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_pear <- pcor.test(data_pear$MZ_MEDIAN, data_pear$BILDANZAHL, data_pear$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_pear <- pcor.test(data_pear$MZ_MEDIAN, data_pear$RANG_KONFIG_PROFIL, data_pear$BILDANZAHL, method = c("spearman"))

# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_broccoli <- pcor.test(data_broccoli$RMA_V_BETRAG, data_broccoli$BILDANZAHL, data_broccoli$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_broccoli <- pcor.test(data_broccoli$RMA_V_BETRAG, data_broccoli$RANG_KONFIG_PROFIL, data_broccoli$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_broccoli <- pcor.test(data_broccoli$MZ_MEDIAN, data_broccoli$BILDANZAHL, data_broccoli$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_broccoli <- pcor.test(data_broccoli$MZ_MEDIAN, data_broccoli$RANG_KONFIG_PROFIL, data_broccoli$BILDANZAHL, method = c("spearman"))

# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_hokkaido <- pcor.test(data_hokkaido$RMA_V_BETRAG, data_hokkaido$BILDANZAHL, data_hokkaido$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_hokkaido <- pcor.test(data_hokkaido$RMA_V_BETRAG, data_hokkaido$RANG_KONFIG_PROFIL, data_hokkaido$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_hokkaido <- pcor.test(data_hokkaido$MZ_MEDIAN, data_hokkaido$BILDANZAHL, data_hokkaido$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_hokkaido <- pcor.test(data_hokkaido$MZ_MEDIAN, data_hokkaido$RANG_KONFIG_PROFIL, data_hokkaido$BILDANZAHL, method = c("spearman"))

# partial correlation between RMA_V_BETRAG and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_rma1_kiwi <- pcor.test(data_kiwi$RMA_V_BETRAG, data_kiwi$BILDANZAHL, data_kiwi$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between RMA_V_BETRAG and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_rma2_kiwi <- pcor.test(data_kiwi$RMA_V_BETRAG, data_kiwi$RANG_KONFIG_PROFIL, data_kiwi$BILDANZAHL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and BILDANZAHL excluded RANG_KONFIG_PROFIL (Z)
pcor_mz1_kiwi <- pcor.test(data_kiwi$MZ_MEDIAN, data_kiwi$BILDANZAHL, data_kiwi$RANG_KONFIG_PROFIL, method = c("spearman"))
# partial correlation between MZ_MEDIAN and RANG_KONFIG_PROFIL excluded BILDANZAHL (Z)
pcor_mz2_kiwi <- pcor.test(data_kiwi$MZ_MEDIAN, data_kiwi$RANG_KONFIG_PROFIL, data_kiwi$BILDANZAHL, method = c("spearman"))
