stu <- read.csv(file = "./student/student-mat.csv", sep = ";", stringsAsFactors=TRUE)
head(stu)
summary(stu)
hist(stu$absences)
median(stu$absences)
table(stu$health)
stu$absences <- ifelse(stu$absences >= 3, TRUE, FALSE)
t.test(stu$G3 ~ stu$absences)
table(stu$absences)
tapply(stu$G3, stu$absences, mean)

boosted.mod <- ps(absences ~ .,
                  data=subset(stu, select=-c(G1, G2, G3)),
                  estimand = "ATE",
                  n.trees = 5000, 
                  interaction.depth=2, 
                  perm.test.iters=0, 
                  verbose=FALSE, 
                  stop.method = c("es.mean"))
summary(boosted.mod)
summary(boosted.mod$gbm.obj,
        n.trees=boosted.mod$desc$es.mean.ATE$n.trees, 
        plot=FALSE)
plot(boosted.mod)
plot(boosted.mod, plots=2)
plot(boosted.mod, plots=3)
bal.table(boosted.mod)
stu$boosted <- get.weights(boosted.mod)
hist(stu$boosted)
design <- svydesign(ids=~1, weights=~boosted, data=stu)
glm1 <- svyglm(G3 ~ absences, design=design)
summary(glm1)
