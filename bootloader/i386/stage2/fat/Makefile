include ../make.mk

all: $(COBJECTS) $(SOBJECTS)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mCC\033[0m $<"

%.o: %.S
	@$(CC) $(CFLAGS) -c $< -o $(BUILDDIR)/$@
	@echo " \033[0;35mAS\033[0m $<"
