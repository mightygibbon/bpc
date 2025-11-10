CC = gcc
CFLAGS = -Wall -Wextra -Wno-unused-function -g
SRCS_DIR = src
GRAMMAR := $(SRCS_DIR)/grammar.y
LEXER := $(SRCS_DIR)/lexer.l
MAIN := $(SRCS_DIR)/main.c
TARGET = bpc

BUILD_DIR = build
PARSER_C := $(BUILD_DIR)/y.tab.c
PARSER_H := $(BUILD_DIR)/y.tab.h
LEXER_C := $(BUILD_DIR)/lex.yy.c
INCLUDES = -I $(BUILD_DIR)

$(TARGET): $(PARSER_C) $(LEXER_C) $(MAIN)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^

$(PARSER_C) $(PARSER_H): $(GRAMMAR) | $(BUILD_DIR)
	yacc -d -o $(PARSER_C) $(GRAMMAR)

$(LEXER_C): $(LEXER) | $(BUILD_DIR)
	flex -o $(LEXER_C) $(LEXER)

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

.PHONY: clean
