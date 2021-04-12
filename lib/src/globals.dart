import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Este arquivo contém algumas variaveis e métodos acessíveis globalmente atráves do aplicativo.

/// Mostra uma mensagem 'snackbar' de conteúdo [message].
// ignore: non_constant_identifier_names
void ShowSnackbarMessage(BuildContext context, String message, [Color color = const Color(0xFFFF3F3F)]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
      message,
      style: TextStyle(
        color: color,
        fontSize: 16.0))));
}

/// Define o *TextStyle* padrão para caixas de entrada de mensagens.
const chatInputTextStyle = TextStyle(
    color: Colors.white,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
    fontSize: 18.0
);

/// Define o *TextStyle* padrão para o *Hint* caixas de entrada de mensagens.
const chatInputHintTextStyle = TextStyle(
    color: Colors.white,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    fontSize: 18.0
);

/// Define o *TextStyle* padrão para caixas de entrada de texto.
const inputTextStyle = TextStyle(
  color: Colors.white,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  fontSize: 16.0
);

/// Define o *TextStyle* padrão para o *Hint* caixas de entrada de texto.
const inputHintTextStyle = TextStyle(
  color: Color(0xFF7F7F7F),
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w400,
  fontSize: 16.0,
);

/// Define o *TextStyle* padrão para botões.
const buttonTextStyle = TextStyle(
  color: Colors.white,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.bold,
  fontSize: 16.0
);

/// Define o *TextStyle* padrão para *appBars*.
const appBarTextStyle = TextStyle(
  color: Colors.white,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.bold,
  fontSize: 20.0
);

/// Define a borda padrão para caixas de entrada de texto quando fora de foco.
const defaultInputBorder = UnderlineInputBorder(
  borderSide: BorderSide(color: Color(0xFF7F7F7F))
);

/// Define a borda padrão para caixas de entrada de texto quando em foco.
const defaultFocusedInputBorder = UnderlineInputBorder(
  borderSide: BorderSide(color: Color(0xFF3F9FFF), width: 2.0)
);

/// Valores de cor, apenas para consulta.
Map<String, Color> colors = {
  'red': Color(0xFFFF3F3F),
  'blue': Color(0xFF3F9FFF),
  'darkgray': Color(0xFF1F1F1F),
  'lightgray': Color(0xFF7F7F7F)
};
