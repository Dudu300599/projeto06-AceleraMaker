//HERC01A JOB (SYS),'PROJBANC-DB2',CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*---------------------------------------------------------*
//* PASSO 0: LIMPEZA DE ARQUIVOS DE SAIDA ANTERIORES
//*---------------------------------------------------------*
//LIMPA    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE HERC01.RELATOR.TXT
  DELETE HERC01.ESTAT.TXT
  DELETE HERC01.ERROS.TXT
  SET MAXCC = 0
//*---------------------------------------------------------*
//* PASSO 1: ORDENAR ARQUIVO DE CLIENTES
//*---------------------------------------------------------*
//SORTCLI  EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTLIB  DD DSN=SYS1.SORTLIB,DISP=SHR
//SORTIN   DD DSN=HERC01.CLIENTES.TXT,DISP=SHR
//SORTOUT  DD DSN=&&CLIENTES,
//            DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(CYL,(1,1)),
//            DCB=(RECFM=FB,LRECL=44,BLKSIZE=4400)
//SYSIN    DD *
  SORT FIELDS=(1,5,CH,A)
/*
//*---------------------------------------------------------*
//* PASSO 2: ORDENAR ARQUIVO DE TRANSACOES
//*---------------------------------------------------------*
//SORTTRX  EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTLIB  DD DSN=SYS1.SORTLIB,DISP=SHR
//SORTIN   DD DSN=HERC01.TRANSACO.TXT,DISP=SHR
//SORTOUT  DD DSN=&&TRANSAC,
//            DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(CYL,(1,1)),
//            DCB=(RECFM=FB,LRECL=20,BLKSIZE=2000)
//SYSIN    DD *
  SORT FIELDS=(1,5,CH,A,6,5,CH,A)
/*
//*---------------------------------------------------------*
//* PASSO 3: EXECUTAR O BATCH BANCARIO COM AMBIENTE DB2
//*---------------------------------------------------------*
//* A execucao via IKJEFT01 permite comandos TSO e DSN
//STEP1    EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=DSN1010.SDSNLOAD,DISP=SHR
//         DD DSN=HERC01.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//* Comandos TSO para conectar ao DB2 e rodar o programa
//SYSTSIN  DD *
  DSN SYSTEM(DB2)
  RUN  PROGRAM(SISTBCH) PLAN(PLANBCH)
  END
/*
//* Arquivos de Entrada Mapeados dos temporarios (&&)
//ARQCLI   DD DSN=&&CLIENTES,DISP=(OLD,DELETE)
//ARQTRX   DD DSN=&&TRANSAC,DISP=(OLD,DELETE)
//* Arquivos de Saida Gerados pelo COBOL
//ARQERR   DD DSN=HERC01.ERROS.TXT,
//            DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=1000)
//ARQREL   DD DSN=HERC01.RELATOR.TXT,
//            DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=50,BLKSIZE=500)
//ARQEST   DD DSN=HERC01.ESTAT.TXT,
//            DISP=(NEW,CATLG,DELETE),UNIT=SYSDA,SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=50,BLKSIZE=500)