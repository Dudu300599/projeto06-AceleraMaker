#include <windows.h>
#include <sqlext.h>
#include <sql.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

SQLHENV henv = NULL;
SQLHDBC hdbc = NULL;

void ConectarBanco(char* status_retorno) {
    SQLRETURN ret;
    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, 0);
    SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);

    SQLCHAR* dsn = (SQLCHAR*)"DSN=BANCO;UID=db2inst1;PWD=senha_super_segura;";
    SQLCHAR outstr[1024];
    SQLSMALLINT outstrlen;

    ret = SQLDriverConnect(hdbc, NULL, dsn, SQL_NTS, outstr, sizeof(outstr), &outstrlen, SQL_DRIVER_NOPROMPT);

    if (SQL_SUCCEEDED(ret)) {
        SQLSetConnectAttr(hdbc, SQL_ATTR_AUTOCOMMIT, (SQLPOINTER)SQL_AUTOCOMMIT_OFF, 0);
        memcpy(status_retorno, "00", 2);
    } else {
        memcpy(status_retorno, "99", 2);
    }
}

void GravarCliente(char* id, char* nome, char* saldo, char* status_retorno) {
    SQLHSTMT hstmt;
    char query[512];
    
    char local_id[6] = {0}, local_nome[33] = {0}, local_saldo[8] = {0};
    
    strncpy(local_id, id, 5); 
    strncpy(local_nome, nome, 32); 
    strncpy(local_saldo, saldo, 7);

    sprintf(query, "SELECT CLI_ID FROM CLIENTES WHERE CLI_ID = %d", atoi(local_id));
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    SQLRETURN ret = SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);

    int existe = 0;
    if (SQL_SUCCEEDED(ret) && SQL_SUCCEEDED(SQLFetch(hstmt))) existe = 1;
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);

    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    if (existe) {
        sprintf(query, "UPDATE CLIENTES SET CLI_NOME = '%s', CLI_SALDO = %d, DT_ATUALIZACAO = CURRENT DATE WHERE CLI_ID = %d", local_nome, atoi(local_saldo), atoi(local_id));
    } else {
        sprintf(query, "INSERT INTO CLIENTES (CLI_ID, CLI_NOME, CLI_SALDO, DT_ATUALIZACAO) VALUES (%d, '%s', %d, CURRENT DATE)", atoi(local_id), local_nome, atoi(local_saldo));
    }

    ret = SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);
    if (SQL_SUCCEEDED(ret)) memcpy(status_retorno, "00", 2);
    else memcpy(status_retorno, "99", 2);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
}


void ConsultarSaldoCliente(char* id, char* ret_existe, char* ret_saldo) {
    SQLHSTMT hstmt;
    char query[256];
    char local_id[6] = {0};
    strncpy(local_id, id, 5);

    sprintf(query, "SELECT CLI_SALDO FROM CLIENTES WHERE CLI_ID = %d", atoi(local_id));
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    SQLRETURN ret = SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);

    if (SQL_SUCCEEDED(ret) && SQL_SUCCEEDED(SQLFetch(hstmt))) {
        memcpy(ret_existe, "1", 1); // Cliente existe
        SQLINTEGER saldo;
        SQLLEN indicator;
        SQLGetData(hstmt, 1, SQL_C_SLONG, &saldo, 0, &indicator);
        
        char saldo_formatado[10];
        sprintf(saldo_formatado, "%09d", saldo);
        memcpy(ret_saldo, saldo_formatado, 9);
    } else {
        memcpy(ret_existe, "0", 1); // Cliente não encontrado
    }
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
}

void InserirTransacaoBanco(char* trx_id, char* cli_id, char* tipo, char* valor) {
    SQLHSTMT hstmt;
    char query[512];
    char l_trx[6]={0}, l_cli[6]={0}, l_tipo[2]={0}, l_valor[10]={0};
    
    strncpy(l_trx, trx_id, 5); strncpy(l_cli, cli_id, 5); 
    strncpy(l_tipo, tipo, 1); strncpy(l_valor, valor, 9);

    sprintf(query, "INSERT INTO TRANSACOES (TRX_ID, CLI_ID, TRX_TIPO, TRX_VALOR, DT_PROCESSAMENTO) VALUES (%d, %d, '%s', %d, CURRENT DATE)", 
            atoi(l_trx), atoi(l_cli), l_tipo, atoi(l_valor));
    
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
}

void AtualizarSaldoBanco(char* cli_id, char* novo_saldo) {
    SQLHSTMT hstmt;
    char query[256];
    char l_cli[6]={0}, l_saldo[10]={0};
    strncpy(l_cli, cli_id, 5); strncpy(l_saldo, novo_saldo, 9);

    sprintf(query, "UPDATE CLIENTES SET CLI_SALDO = %d, DT_ATUALIZACAO = CURRENT DATE WHERE CLI_ID = %d", atoi(l_saldo), atoi(l_cli));
    
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
}

void InserirErroBanco(char* cli_id, char* descricao) {
    SQLHSTMT hstmt;
    char query[512];
    char l_cli[6]={0}, l_desc[101]={0};
    strncpy(l_cli, cli_id, 5); strncpy(l_desc, descricao, 100);

    sprintf(query, "INSERT INTO ERROS_PROCESSAMENTO (CLI_ID, DESCRICAO_ERRO, DT_OCORRENCIA) VALUES (%d, '%s', CURRENT TIMESTAMP)", atoi(l_cli), l_desc);
    
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
    SQLExecDirect(hstmt, (SQLCHAR*)query, SQL_NTS);
    SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
}

void EfetuarCommit() {
    SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
}

void DesconectarBanco() {
    if (hdbc != NULL) {
        SQLDisconnect(hdbc);
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
    }
    if (henv != NULL) {
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
    }
}

void EfetuarRollback() {
    SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
}

SQLHSTMT hstmtCursor = NULL;

void AbrirCursorRelatorio(char* status_retorno) {
    SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmtCursor);
    
    char* query = "SELECT C.CLI_ID, "
                  "COALESCE(SUM(CASE WHEN T.TRX_TIPO = 'C' THEN T.TRX_VALOR ELSE 0 END), 0) AS TOT_CRED, "
                  "COALESCE(SUM(CASE WHEN T.TRX_TIPO = 'D' THEN T.TRX_VALOR ELSE 0 END), 0) AS TOT_DEB "
                  "FROM CLIENTES C "
                  "LEFT JOIN TRANSACOES T ON C.CLI_ID = T.CLI_ID "
                  "GROUP BY C.CLI_ID "
                  "ORDER BY C.CLI_ID";

    SQLRETURN ret = SQLExecDirect(hstmtCursor, (SQLCHAR*)query, SQL_NTS);
    if (SQL_SUCCEEDED(ret)) {
        memcpy(status_retorno, "00", 2);
    } else {
        memcpy(status_retorno, "99", 2);
    }
}

void LerCursorRelatorio(char* cli_id, char* tot_cred, char* tot_deb, char* status_retorno) {
    SQLRETURN ret = SQLFetch(hstmtCursor);
    
    if (ret == SQL_NO_DATA) {
        memcpy(status_retorno, "10", 2);
    } else if (SQL_SUCCEEDED(ret)) {
        SQLINTEGER id, cred, deb;
        SQLLEN ind1, ind2, ind3;
        
        SQLGetData(hstmtCursor, 1, SQL_C_SLONG, &id, 0, &ind1);
        SQLGetData(hstmtCursor, 2, SQL_C_SLONG, &cred, 0, &ind2);
        SQLGetData(hstmtCursor, 3, SQL_C_SLONG, &deb, 0, &ind3);
        
        char buf1[6], buf2[10], buf3[10];
        sprintf(buf1, "%05d", id);
        sprintf(buf2, "%09d", cred);
        sprintf(buf3, "%09d", deb);
        
        strncpy(cli_id, buf1, 5);
        strncpy(tot_cred, buf2, 9);
        strncpy(tot_deb, buf3, 9);
        memcpy(status_retorno, "00", 2);
    } else {
        memcpy(status_retorno, "99", 2);
    }
}

void FecharCursorRelatorio() {
    if (hstmtCursor != NULL) {
        SQLFreeHandle(SQL_HANDLE_STMT, hstmtCursor);
        hstmtCursor = NULL;
    }
}
