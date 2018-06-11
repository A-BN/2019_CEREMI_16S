library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(cowplot)
library(ape)

pred <- read_delim("Desktop/beta_1000/predires.trim.contigs.good.unique.good.filter.precluster.pick.pick.opti_mcc.braycurtis.0.03.square.dist", 
                   "\t", escape_double = FALSE, col_names = FALSE, 
                   trim_ws = TRUE, skip = 1)

patients <- read_delim("Desktop/beta_1000/patients.csv", 
                       "\t", escape_double = FALSE, trim_ws = TRUE, col_types = cols(.default = "c"))

patients$id_selle <- str_replace_all(string = patients$id_selle, pattern = "-", replacement = "_")
# extract_ctrl_df <- as.data.frame(cbind("TEXT12", 666, unique(patients$jour)))
# names(extract_ctrl_df) <- names(patients)
# patients <- rbind(patients, extract_ctrl_df)

prob_extract_id <- c("TEXT12", "464_NNYO","754_VPYQ","062_QLID","745_BQTF","782_IOFW","718_LNPY","672_YXBV","213_MRUE","575_QFRR","651_VRIP","464_KCWC","368_OXGJ","064_YQMG")


princopa_pred <- pcoa(D = pred[,-1])
pred_vectors <- as.data.frame(cbind(id_selle = as.character(pred$X1), princopa_pred$vectors[,1:5]))

pred_toplot <-
 inner_join(pred_vectors, patients, by = "id_selle") %>%
  mutate(extract = ifelse(test = id_selle %in% prob_extract_id, yes = TRUE, no = FALSE))
  
my_plot <-  
pred_toplot %>%
  mutate(ctrl = ifelse(test = id_selle == "TEXT12", yes = TRUE, no = FALSE)) %>%
  filter(str_detect(jour, "")) %>%
  ggplot()+
    geom_point(aes(x = Axis.1, y = Axis.2, color = extract, shape = ctrl), size = 5, alpha = 0.8)+
    theme(axis.text.x = element_blank(), axis.text.y = element_blank(), legend.position = "none")+
    scale_color_grey(start = 0, end = 0.4)+
    facet_wrap(~jour)

my_plot
#cowplot::save_plot(plot = my_plot, filename = "Desktop/pcoa.pdf", base_height = 7, base_aspect_ratio = 2)
