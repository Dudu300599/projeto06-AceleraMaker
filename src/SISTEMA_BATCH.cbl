IDENTIFICATION DIVISION.
       PROGRAM-ID. SISTEMA-BATCH.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *> Arquivos Originais
           SELECT ARQ-CLIENTES ASSIGN TO "../data/CLIENTES.TXT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUS-CLIENTES.
           SELECT ARQ-TRANSACOES ASSIGN TO "../data/TRANSACOES.TXT"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUS-TRANS.

      *> Arquivos Ordenados
           SELECT ARQ-CLI-ORD ASSIGN TO "../data/CLIENTES_ORD.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-TRX-ORD ASSIGN TO "../data/TRANSACOES_ORD.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.

      *> Arquivos Temporarios de Trabalho para o SORT
           SELECT WORK-CLIENTES ASSIGN TO "WORKCLI".
           SELECT WORK-TRANS ASSIGN TO "WORKTRX".

      *> Arquivos de Saida (Logs e Relatorios)
           SELECT ARQ-ERROS ASSIGN TO "../data/ERROS.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-RELATORIO ASSIGN TO "../data/RELATORIO.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ARQ-ESTATISTICAS ASSIGN TO "../data/ESTATISTICAS.TXT"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-CLIENTES.
           COPY "CLIENTES.cpy".
       FD  ARQ-TRANSACOES.
           COPY "TRANSACOES.cpy".

      *> Estruturas para a ordenacao
       SD  WORK-CLIENTES.
       01  REG-WORK-CLI.
           05 WCLI-ID             PIC 9(05).
           05 FILLER              PIC X(39).

       SD  WORK-TRANS.
       01  REG-WORK-TRANS.
           05 WTRX-CLI-ID         PIC 9(05).
           05 FILLER              PIC X(15).

       FD  ARQ-CLI-ORD.
       01  REG-CLI-ORD            PIC X(44).
       FD  ARQ-TRX-ORD.
       01  REG-TRX-ORD            PIC X(20).

       FD  ARQ-ERROS.
       01  REG-ERRO               PIC X(100).
       FD  ARQ-RELATORIO.
       01  REG-RELATORIO          PIC X(50).
       FD  ARQ-ESTATISTICAS.
       01  REG-ESTAT              PIC X(50).
       
       WORKING-STORAGE SECTION.
       01  WS-CONTROLES.
           05 WS-STATUS-CLIENTES  PIC X(02).
           05 WS-STATUS-TRANS     PIC X(02).
           05 WS-EOF-CLIENTES     PIC X(01) VALUE 'N'.
              88 FIM-DOS-CLIENTES VALUE 'S'.
           05 WS-EOF-TRANS        PIC X(01) VALUE 'N'.
              88 FIM-DAS-TRANS    VALUE 'S'.
           05 WS-DB-STATUS        PIC X(02).
           
       01  WS-DADOS-TRANSACAO.
           05 WS-CLI-EXISTE       PIC X(01).
           05 WS-SALDO-ATUAL-TXT  PIC X(09).
           05 WS-SALDO-ATUAL-NUM  PIC 9(09).
           05 WS-VALOR-TRANS-NUM  PIC 9(09).
           05 WS-NOVO-SALDO-NUM   PIC 9(09).
           05 WS-NOVO-SALDO-TXT   PIC 9(09).
           05 WS-MENSAGEM-ERRO    PIC X(100).

       01  WS-CONTROLE-CURSOR.
           05 WS-CURSOR-STATUS    PIC X(02) VALUE "00".    

       01  WS-CONTADORES.
           05 WS-TOT-CLI-LIDOS    PIC 9(06) VALUE ZEROS.
           05 WS-TOT-TRX-LIDOS    PIC 9(06) VALUE ZEROS.
           05 WS-TOT-TRX-OK       PIC 9(06) VALUE ZEROS.
           05 WS-TOT-CREDITOS     PIC 9(06) VALUE ZEROS.
           05 WS-TOT-DEBITOS      PIC 9(06) VALUE ZEROS.
           05 WS-TOT-ERROS        PIC 9(06) VALUE ZEROS.
           05 WS-CONTA-COMMIT     PIC 9(04) VALUE ZEROS.

      *> Layouts Exatos de Saida dos Relatorios
       01  WS-REL-DETALHE.
           05 FILLER              PIC X(09) VALUE "CLIENTE: ".
           05 WS-REL-CLI-ID       PIC X(05).
       01  WS-REL-CRED.
           05 FILLER              PIC X(16) VALUE "TOTAL CREDITOS: ".
           05 WS-REL-TOT-CRED     PIC 9(09).
       01  WS-REL-DEB.
           05 FILLER              PIC X(16) VALUE "TOTAL DEBITOS:  ".
           05 WS-REL-TOT-DEB      PIC 9(09).

       01  WS-ESTAT-LAYOUT.
           05 WS-E-CLI.
              10 FILLER PIC X(28) VALUE " CLIENTES PROCESSADOS.....: ".
              10 WS-V-CLI PIC 9(06).
           05 WS-E-TRX.
              10 FILLER PIC X(28) VALUE " TRANSACOES PROCESSADAS...: ".
              10 WS-V-TRX PIC 9(06).
           05 WS-E-CRED.
              10 FILLER PIC X(28) VALUE " CREDITOS PROCESSADOS.....: ".
              10 WS-V-CRED PIC 9(06).
           05 WS-E-DEB.
              10 FILLER PIC X(28) VALUE " DEBITOS PROCESSADOS......: ".
              10 WS-V-DEB PIC 9(06).
           05 WS-E-ERR.
              10 FILLER PIC X(28) VALUE " ERROS ENCONTRADOS........: ".
              10 WS-V-ERR PIC 9(06).

       PROCEDURE DIVISION.
       0000-PRINCIPAL.
           DISPLAY "INICIANDO SISTEMA BANCARIO BATCH...".
           PERFORM 0500-ORDENAR-ARQUIVOS.
           PERFORM 1000-INICIALIZAR.
           PERFORM 2000-PROCESSAR-CLIENTES.
           PERFORM 3000-PROCESSAR-TRANSACOES.
           PERFORM 4000-GERAR-RELATORIO-CURSOR.
           PERFORM 5000-FINALIZAR.
           STOP RUN.
           STOP RUN.

       0500-ORDENAR-ARQUIVOS.
           DISPLAY "ORDENANDO ARQUIVOS DE ENTRADA...".
           SORT WORK-CLIENTES ON ASCENDING KEY WCLI-ID 
                USING ARQ-CLIENTES GIVING ARQ-CLI-ORD.
           SORT WORK-TRANS ON ASCENDING KEY WTRX-CLI-ID 
                USING ARQ-TRANSACOES GIVING ARQ-TRX-ORD.

       1000-INICIALIZAR.
      *> Agora abrimos as versoes ordenadas
           OPEN INPUT ARQ-CLI-ORD.
           OPEN INPUT ARQ-TRX-ORD.
           OPEN OUTPUT ARQ-ERROS.
           OPEN OUTPUT ARQ-RELATORIO.
           OPEN OUTPUT ARQ-ESTATISTICAS.
           
           CALL "ConectarBanco" USING WS-DB-STATUS.
           IF WS-DB-STATUS NOT = "00"
               DISPLAY "--> ERRO FATAL AO CONECTAR NO DB2."
               STOP RUN
           END-IF.

       2000-PROCESSAR-CLIENTES.
           DISPLAY "-----------------------------------------".
           DISPLAY "1. CARGA INICIAL DE CLIENTES".
           PERFORM 2100-LER-CLIENTE.
           
           PERFORM UNTIL FIM-DOS-CLIENTES
               ADD 1 TO WS-TOT-CLI-LIDOS
               CALL "GravarCliente" USING CLI-ID-TXT CLI-NOME-TXT 
                                          CLI-SALDO-TXT WS-DB-STATUS
               PERFORM 2100-LER-CLIENTE
           END-PERFORM.
           CALL "EfetuarCommit".

       2100-LER-CLIENTE.
      *> Lemos o arquivo ordenado para dentro da nossa struct original
           READ ARQ-CLI-ORD INTO REG-CLIENTE
               AT END SET FIM-DOS-CLIENTES TO TRUE
           END-READ.

       3000-PROCESSAR-TRANSACOES.
           DISPLAY "-----------------------------------------".
           DISPLAY "2. PROCESSAMENTO DE TRANSACOES".
           PERFORM 3100-LER-TRANSACAO.
           PERFORM UNTIL FIM-DAS-TRANS
               ADD 1 TO WS-TOT-TRX-LIDOS
               PERFORM 3200-VALIDAR-E-GRAVAR
               PERFORM 3100-LER-TRANSACAO
           END-PERFORM.
           
           CALL "EfetuarCommit".

       3100-LER-TRANSACAO.
           READ ARQ-TRX-ORD INTO REG-TRANSACAO
               AT END SET FIM-DAS-TRANS TO TRUE
           END-READ.

       3200-VALIDAR-E-GRAVAR.
           CALL "ConsultarSaldoCliente" USING TRX-CLI-ID-TXT 
                                              WS-CLI-EXISTE 
                                              WS-SALDO-ATUAL-TXT.
           COMPUTE WS-VALOR-TRANS-NUM = FUNCTION NUMVAL(TRX-VALOR-TXT).
           
           IF WS-CLI-EXISTE = "0"
               MOVE "ERRO: CLIENTE NAO ENCONTRADO." TO WS-MENSAGEM-ERRO
               PERFORM 3300-GRAVAR-ERRO
           ELSE IF WS-VALOR-TRANS-NUM <= 0
               MOVE "ERRO: VALOR DA TRANSACAO ZERADO." TO WS-MENSAGEM-ERRO
               PERFORM 3300-GRAVAR-ERRO
           ELSE IF TRX-TIPO-TXT NOT = "D" AND TRX-TIPO-TXT NOT = "C"
               MOVE "ERRO: TIPO DE TRANSACAO INVALIDO." TO WS-MENSAGEM-ERRO
               PERFORM 3300-GRAVAR-ERRO
           ELSE
               COMPUTE WS-SALDO-ATUAL-NUM = FUNCTION NUMVAL(WS-SALDO-ATUAL-TXT)
               IF TRX-TIPO-TXT = "D"
                   IF WS-VALOR-TRANS-NUM > WS-SALDO-ATUAL-NUM
                       MOVE "ERRO: SALDO INSUFICIENTE." TO WS-MENSAGEM-ERRO
                       PERFORM 3300-GRAVAR-ERRO
                   ELSE
                       SUBTRACT WS-VALOR-TRANS-NUM FROM WS-SALDO-ATUAL-NUM 
                                                   GIVING WS-NOVO-SALDO-NUM
                       ADD 1 TO WS-TOT-DEBITOS
                       PERFORM 3400-EFETIVAR-TRANSACAO
                   END-IF
               ELSE
                   ADD WS-VALOR-TRANS-NUM TO WS-SALDO-ATUAL-NUM 
                                          GIVING WS-NOVO-SALDO-NUM
                   ADD 1 TO WS-TOT-CREDITOS
                   PERFORM 3400-EFETIVAR-TRANSACAO
               END-IF
           END-IF.
           
           ADD 1 TO WS-CONTA-COMMIT.
           IF WS-CONTA-COMMIT >= 100
               CALL "EfetuarCommit"
               MOVE 0 TO WS-CONTA-COMMIT
           END-IF.

       3300-GRAVAR-ERRO.
           ADD 1 TO WS-TOT-ERROS.
           DISPLAY "  [X] REJEITADA TRX: " TRX-ID-TXT " - " WS-MENSAGEM-ERRO.
           STRING "TRX: " TRX-ID-TXT " | CLI: " TRX-CLI-ID-TXT " | " 
                  WS-MENSAGEM-ERRO DELIMITED BY SIZE INTO REG-ERRO
           WRITE REG-ERRO.
           CALL "InserirErroBanco" USING TRX-CLI-ID-TXT WS-MENSAGEM-ERRO.

       3400-EFETIVAR-TRANSACAO.
           MOVE WS-NOVO-SALDO-NUM TO WS-NOVO-SALDO-TXT.
           
           CALL "AtualizarSaldoBanco" USING TRX-CLI-ID-TXT WS-NOVO-SALDO-TXT.
           
           IF WS-DB-STATUS = "00"
               CALL "InserirTransacaoBanco" USING TRX-ID-TXT TRX-CLI-ID-TXT 
                                                  TRX-TIPO-TXT TRX-VALOR-TXT
               IF WS-DB-STATUS = "00"
                   DISPLAY "  [OK] APROVADA TRX: " TRX-ID-TXT
                   ADD 1 TO WS-TOT-TRX-OK
               ELSE
                   DISPLAY "  [X] ERRO AO INSERIR TRANSACAO. ROLLBACK!"
                   CALL "EfetuarRollback"
                   PERFORM 3300-GRAVAR-ERRO
               END-IF
           ELSE
               DISPLAY "  [X] ERRO AO ATUALIZAR SALDO. ROLLBACK!"
               CALL "EfetuarRollback"
               PERFORM 3300-GRAVAR-ERRO
           END-IF.

       4000-GERAR-RELATORIO-CURSOR.
           DISPLAY "-----------------------------------------".
           DISPLAY "3. GERANDO RELATORIO VIA CURSOR DB2...".
           
           CALL "AbrirCursorRelatorio" USING WS-CURSOR-STATUS.
           
           IF WS-CURSOR-STATUS = "00"
               PERFORM UNTIL WS-CURSOR-STATUS = "10"
                   CALL "LerCursorRelatorio" USING WS-REL-CLI-ID 
                                                   WS-REL-TOT-CRED 
                                                   WS-REL-TOT-DEB 
                                                   WS-CURSOR-STATUS

                   IF WS-CURSOR-STATUS = "00"
                       WRITE REG-RELATORIO FROM WS-REL-DETALHE
                       WRITE REG-RELATORIO FROM WS-REL-CRED
                       WRITE REG-RELATORIO FROM WS-REL-DEB
                   END-IF
               END-PERFORM
               
               CALL "FecharCursorRelatorio"
               DISPLAY "   -> RELATORIO DETALHADO GRAVADO COM SUCESSO."
           ELSE
               DISPLAY "   -> ERRO AO ABRIR CURSOR DO DB2."
           END-IF.
  
       5000-FINALIZAR.
      *> Preenche e grava o layout exato de Estatisticas
           MOVE WS-TOT-CLI-LIDOS TO WS-V-CLI.
           MOVE WS-TOT-TRX-LIDOS TO WS-V-TRX.
           MOVE WS-TOT-CREDITOS  TO WS-V-CRED.
           MOVE WS-TOT-DEBITOS   TO WS-V-DEB.
           MOVE WS-TOT-ERROS     TO WS-V-ERR.

           WRITE REG-ESTAT FROM " ****************************************".
           WRITE REG-ESTAT FROM " ESTATISTICAS DE PROCESSAMENTO".
           WRITE REG-ESTAT FROM " ****************************************".
           WRITE REG-ESTAT FROM WS-E-CLI.
           WRITE REG-ESTAT FROM WS-E-TRX.
           WRITE REG-ESTAT FROM WS-E-CRED.
           WRITE REG-ESTAT FROM WS-E-DEB.
           WRITE REG-ESTAT FROM WS-E-ERR.
           WRITE REG-ESTAT FROM " FIM DO PROCESSAMENTO".

           CLOSE ARQ-CLI-ORD ARQ-TRX-ORD ARQ-ERROS.
           CLOSE ARQ-RELATORIO ARQ-ESTATISTICAS.
           CALL "DesconectarBanco".

           