
CFLAGS += -Wall -std=c11 -I./include -g

BINDIR := bin

PROGNAMES = \
	cat \
	false \
	getty \
	head \
	hexdump \
	hlsym \
	kill \
	link \
	ln \
	lnum \
	ls \
	mkdir \
	mkfifo \
	mknod \
	more \
	mount \
	mv \
	ping \
	rm \
	rmdir \
	seq \
	sh \
	sort \
	stat \
	sync \
	tee \
	touch \
	true \
	tty \
	umount \
	uniq \
	unlink \
	wc \


PROGBINS := $(patsubst %,$(BINDIR)/%,$(PROGNAMES))
PROGBINSIU := $(patsubst %,$(BINDIR)/iu/iu%,$(PROGNAMES))

CLEAN-LIST :=

# Arg 1 is the build target name
# Arg 2 is the build target dependencies
# Arg 3 is any extra flags to be given to the compiler
define def_util_build_rule
$(1): $(2) | $(BINDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) $(3) $(2) -o $(1)
endef


define def_unil
dir := ./src/$(1)

ldflags-y :=
objs-y :=
common-objs-y :=

include $$(dir)/Makefile

common-obj-list := $$(patsubst %,./src/common/%,$$(common-objs-y))
obj-list := $$(patsubst %,$$(dir)/%,$$(objs-y))

$$(eval $$(call def_util_build_rule,./bin/$(1),$$(obj-list) $$(common-obj-list), ))

CLEAN-LIST += $$(obj-list) $$(common-obj-list)
endef

.PHONY: all clean
all: $(PROGBINS) $(PROGBINSIU)

$(BINDIR)/iu: | $(BINDIR)
	@mkdir $(BINDIR)/iu

$(BINDIR):
	@mkdir $(BINDIR)

%.c: %.l
	@echo "$< -o $@"
	@$(LEX) $(LFLAGS) -o $@ $<

%.o: %.c
	@echo "$< -o $@"
	@$(CC) $(CFLAGS) -c $< -o $@

$(BINDIR)/iu/iu%: $(BINDIR)/% | $(BINDIR)/iu
	@echo "$< -> $@"
	@cp $< $@

$(foreach util,$(PROGNAMES),$(eval $(call def_unil,$(util))))

define prog_shortcut
.PHONY: $(1)
$(1): $$(BINDIR)/$(1)
endef

$(foreach prog,$(PROGNAMES),$(eval $(call prog_shortcut,$(prog))))

clean:
	@rm -f $(CLEAN-LIST)
	@rm -f $(PROGBINS)
	@rm -fr $(BINDIR)

