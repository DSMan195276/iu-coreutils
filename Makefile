
CFLAGS += -Wall -std=c11 -I./include -g

BINDIR := bin

PROGNAMES := \
	cat \
	ls \
	lnum \
	hlsym \
	true \
	false \
	seq \
	tee \
	wc \
	uniq \

PROGBINS := $(patsubst %,$(BINDIR)/%,$(PROGNAMES))
PROGBINSIU := $(patsubst %,$(BINDIR)/iu/iu%,$(PROGNAMES))

COMMONSRC := $(wildcard ./common/*.c)
COMMONOBJ := $(COMMONSRC:.c=.o)
COMMONAR := ./common.a

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

$(COMMONAR): $(COMMONOBJ)
	@echo "common/*.o -o ./common.a"
	@$(AR) rcs $@ $(COMMONOBJ)

define prog_shortcut
.PHONY: $(1)
$(1): $$(BINDIR)/$(1)
endef

$(foreach prog,$(PROGNAMES),$(eval $(call prog_shortcut,$(prog))))

$(BINDIR)/%: %.c $(COMMONAR) | $(BINDIR)
	@echo "$< -o $@"
	@$(CC) $(CFLAGS) $< $(COMMONAR) -o $@

$(BINDIR)/iu/iu%: $(BINDIR)/% | $(BINDIR)/iu
	@echo "$< -> $@"
	@cp -a $< $@

clean:
	@rm -f $(COMMONAR)
	@rm -f $(COMMONOBJ)
	@rm -f $(PROGBINS)
	@rm -fr $(BINDIR)

