DECLARE
  -- ===================================== PARAMETROS DE ENTRADA =====================================
  p_nNumFact ACSELX.FACTURA.NumFact%TYPE      := 1166552392;   -- <<< documento a refinanciar
  p_nIdepol  ACSELX.CERTIFICADO.IdePol%TYPE   := 1629307181;   -- <<< poliza del certificado
  p_nNumCert ACSELX.CERTIFICADO.NumCert%TYPE  := 1; -- <<< certificado
  p_cMotRefi ACSELX.LVAL.CODLVAL%TYPE := 'SOL';
  p_cObservacion  VARCHAR2(250) := 'Cambio de responsable de pago al asegurado';
  -- ==================================================================================================

  -- Regla de cambio de plan
  --kPlanSolJur     CONSTANT VARCHAR2(6) := 'CON020';
  kPlanSolNat     CONSTANT VARCHAR2(6) := 'CUP254';
  --kPlanUsdJur     CONSTANT VARCHAR2(6) := 'CON002';
  kPlanUsdNat     CONSTANT VARCHAR2(6) := 'CUP201';
  -- Motivo de refinanciamiento (LOV_MOTREFIN de FIN00012: "A SOLICITUD" / "INTERNO PARA COMPENSAR")
  kMotivoDesc     CONSTANT VARCHAR2(30) := 'A SOLICITUD';
  kSi             CONSTANT VARCHAR2(1)  := 'S';
  kNo             CONSTANT VARCHAR2(1)  := 'N';

  -- ----------------------------- Items de FIN00010 -------------------------------------------------
  -- C00 (bloque de control)
  TYPE tC00_10 IS RECORD (
    nNumSesion      NUMBER,  -- B01_Q (filtros)  -> solo IdSession (se llena con el boton Doc)
    cIndPolTransc   VARCHAR2(1),
    nNumOperMacsi   NUMBER,
    cIndOkRefinanc  VARCHAR2(2));

  -- B02_1 (documentos a financiar, tabla ACSELX.TEMP_DOCS_FINANC)
  TYPE tB02_1 IS RECORD (
    NumFact         ACSELX.FACTURA.NumFact%TYPE,
    NumId           ACSELX.FACTURA.NumId%TYPE,
    CodMoneda       ACSELX.FACTURA.CodMoneda%TYPE,
    MtoFactMoneda   ACSELX.FACTURA.MtoFactMoneda%TYPE,
    StsFact         ACSELX.FACTURA.StsFact%TYPE,
    TipoDoc         ACSELX.FACTURA.TipoDoc%TYPE,
    NumOper         ACSELX.FACTURA.NumOper%TYPE,
    IdeFact         ACSELX.FACTURA.IdeFact%TYPE,
    IdSession       NUMBER);

  -- B03_1 (financiamientos, tabla ACSELX.COND_FINANCIAMIENTO) + items calculados en el POST-QUERY
  TYPE tB03_1 IS RECORD (
    NumFinanc       ACSELX.COND_FINANCIAMIENTO.NumFinanc%TYPE,
    NumOper         ACSELX.COND_FINANCIAMIENTO.NumOper%TYPE,
    IdePol          ACSELX.COND_FINANCIAMIENTO.IdePol%TYPE,
    NumCert         ACSELX.COND_FINANCIAMIENTO.NumCert%TYPE,
    TipoFin         ACSELX.COND_FINANCIAMIENTO.TipoFin%TYPE,
    CodPlan         ACSELX.COND_FINANCIAMIENTO.CodPlan%TYPE,
    ModPlan         ACSELX.COND_FINANCIAMIENTO.ModPlan%TYPE,
    CodMoneda       ACSELX.COND_FINANCIAMIENTO.CodMoneda%TYPE,
    TipoId          ACSELX.COND_FINANCIAMIENTO.TipoId%TYPE,
    NumId           ACSELX.COND_FINANCIAMIENTO.NumId%TYPE,
    DvId            ACSELX.COND_FINANCIAMIENTO.DvId%TYPE,
    MtoPago         ACSELX.COND_FINANCIAMIENTO.MtoPago%TYPE,
    MtoNetoFrac     ACSELX.COND_FINANCIAMIENTO.MtoNetoFrac%TYPE,
    NumRefinanc     ACSELX.COND_FINANCIAMIENTO.NumRefinanc%TYPE,
    nNumPol         ACSELX.POLIZA.NumPol%TYPE,
    cCodProd        ACSELX.POLIZA.CodProd%TYPE,
    cCodCia         ACSELX.POLIZA.CodCia%TYPE,
    cCodInter       ACSELX.PART_INTER_POL.CodInter%TYPE,
    cCodCli         ACSELX.CLIENTE.CodCli%TYPE,
    nMtoOper        NUMBER(14,2),
    nMtoComOper     NUMBER(14,2),
    nMtoPendiente   NUMBER(14,2),
    nMtoCob         NUMBER(14,2),
    nPrimaTotal     NUMBER(14,2),
    cSeleccion      VARCHAR2(1));
  TYPE tTabB03_1 IS TABLE OF tB03_1 INDEX BY PLS_INTEGER;

  -- B03_2 (totales y estado de la operacion de refinanciamiento)
  TYPE tB03_2 IS RECORD (
    nNumRefinanc      ACSELX.COND_FINANCIAMIENTO.NumRefinanc%TYPE,
    nNumOper          ACSELX.OPER_POL.NumOper%TYPE,
    cTipoFinanc       VARCHAR2(3),
    nTotMtoOper       NUMBER(14,2),
    nTotComiOper      NUMBER(14,2),
    nTotMtoPendiente  NUMBER(14,2),
    nMtoTotalNeto     NUMBER(14,2),
    nMtoTotalPrima    NUMBER(14,2),
    nMtoTotalFinanc   NUMBER(14,2),
    cCodMonedaAnt     VARCHAR2(3),
    dFecEmi           DATE,
    dFecIniVig        DATE,
    dFecFinVig        DATE,
    cIndTranscripcion VARCHAR2(1),
    cFinFactPend      VARCHAR2(1),
    cTipoFinFP        VARCHAR2(3),
    cIndGrupo         VARCHAR2(1),
    cCodCliAnt        ACSELX.CLIENTE.CodCli%TYPE,
    cCodInterAnt      ACSELX.PART_INTER_POL.CodInter%TYPE,
    cIndDSAnt         VARCHAR2(3),
    cCodCiaAnt        ACSELX.POLIZA.CodCia%TYPE);

  -- ----------------------------- Items de FIN00012 -------------------------------------------------
  TYPE tC00_12 IS RECORD (
    nNumRefinanc      ACSELX.COND_FINANCIAMIENTO.NumRefinanc%TYPE,
    nNumOper          ACSELX.OPER_POL.NumOper%TYPE,
    cTipoFinanc       VARCHAR2(3),
    nTotMtoOper       NUMBER(14,2),
    nTotComiOper      NUMBER(14,2),
    cCodMonedaAnt     VARCHAR2(3),
    dFecIniVig        DATE,
    dFecFinVig        DATE,
    dFecEmi           DATE,
    cIndTranscripcion VARCHAR2(1),
    nNumOperMacsi     NUMBER,
    cIndPolTransc     VARCHAR2(1),
    cIndFactPend      VARCHAR2(1),
    cIndAutoriza      VARCHAR2(1),
    cIndCrear         VARCHAR2(1),
    cCodPlanFracc     ACSELX.PLAN_FINANCIAMIENTO.CodPlan%TYPE);

  TYPE tC01 IS RECORD(                                    -- copia para detectar cambios (C01)
    cTipoFinAux       ACSELX.COND_FINANCIAMIENTO.TipoFin%TYPE,
    cIndIntInicialAux ACSELX.COND_FINANCIAMIENTO.IndIntInicial%TYPE,
    nFrecuenciaAux    ACSELX.COND_FINANCIAMIENTO.Frecuencia%TYPE,
    nPorcInicialAux   ACSELX.COND_FINANCIAMIENTO.PorcInicial%TYPE,
    nPorcInteresAux   ACSELX.COND_FINANCIAMIENTO.PorcInteres%TYPE,
    nCantGirosAux     ACSELX.COND_FINANCIAMIENTO.CantGiros%TYPE,
    dFec1erVencAux    DATE,
    nMtoGastosAux     ACSELX.COND_FINANCIAMIENTO.MtoGastos%TYPE);

  TYPE tB04_1 IS RECORD (
    cCodMotvAnul      VARCHAR2(4),
    cDescMotvAnul     VARCHAR2(200),
    cTextMotvAnul     VARCHAR2(250));

  -- V. Globales
  gC00_10      tC00_10;
  gIdSession   NUMBER;
  gB02_1       tB02_1;
  gB03_1       tTabB03_1;
  gB03_2       tB03_2;
  gC00_12      tC00_12;
  gB01_1       ACSELX.RESP_PAGO_REFRA%ROWTYPE;             -- fila de B01_1 (responsable de pago)
  gB01_1Ant    ACSELX.RESP_PAGO_REFRA.CodCli%TYPE;         -- CodCli original de la fila (para el UPDATE)
  gB01_1TipFin VARCHAR2(3);                                -- :B01_1.cTipoFin (FIN00012)
  gCF12        ACSELX.COND_FINANCIAMIENTO%ROWTYPE;         -- fila de B03_1 (FIN00012)
  gFec1erVenc  DATE;                                       -- :B03_1.dFec1erVenc (FIN00012)
  gC01         tC01;
  gB04_1       tB04_1;
  gCliAseg     ACSELX.CLIENTE%ROWTYPE;                     -- asegurado (nuevo responsable)
  gPaso        VARCHAR2(80);
  gCommit      BOOLEAN := FALSE;
  gInicio      NUMBER := DBMS_UTILITY.GET_TIME;

  -- ================================================================================================
  -- UTILITARIOS DE MENSAJES (equivalentes a FR_Message / FR_Mensaje / FR_Error de las formas)
  -- ================================================================================================
  PROCEDURE P_LOG(p_cMsg VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE,'HH24:MI:SS')||' | '||RPAD(NVL(gPaso,'-'),36)||' | '||p_cMsg);
  END P_LOG;

  PROCEDURE INICIO_PASO(p_cPaso VARCHAR2, p_cUbicacion VARCHAR2) IS
  BEGIN
    gPaso := p_cPaso;
    DBMS_OUTPUT.PUT_LINE(RPAD('-',120,'-'));
    P_LOG('>> INICIO  ['||p_cUbicacion||']');
  END INICIO_PASO;

  PROCEDURE FIN_PASO(p_cMsg VARCHAR2 DEFAULT NULL) IS
  BEGIN
    P_LOG('<< OK'||CASE WHEN p_cMsg IS NOT NULL THEN ': '||p_cMsg END);
  END FIN_PASO;

  PROCEDURE P_ERROR(p_cMsg VARCHAR2) IS                    -- FR_Error: detiene el proceso
  BEGIN
    P_LOG('!! ERROR: '||p_cMsg);
    RAISE_APPLICATION_ERROR(-20100, '['||gPaso||'] '||SUBSTR(p_cMsg,1,1900));
  END P_ERROR;

  PROCEDURE P_AVISO(p_cMsg VARCHAR2) IS                    -- FR_Mensaje('AL_ALERTA',...) informativo
  BEGIN
    P_LOG('** ALERTA: '||p_cMsg);
  END P_AVISO;

  -- ================================================================================================
  -- 00. Validacion de parametros (control del bloque; en la forma lo hace el usuario al elegir)
  -- ================================================================================================
  PROCEDURE VALIDAR_PARAMETROS IS
    nCant NUMBER;
  BEGIN
    INICIO_PASO('00.PARAMETROS','Bloque anonimo: validacion de parametros');
    P_LOG('p_nNumFact='||p_nNumFact||' p_nIdepol='||p_nIdepol||' p_nNumCert='||p_nNumCert);
    P_LOG('p_cObservacion='||p_cObservacion);

    IF p_nNumFact IS NULL THEN P_ERROR('Debe indicar el numero de documento a refinanciar (p_nNumFact)'); END IF;
    IF p_nIdepol  IS NULL THEN P_ERROR('Debe indicar la poliza (p_nIdepol)'); END IF;
    IF p_nNumCert IS NULL THEN P_ERROR('Debe indicar el certificado (p_nNumCert)'); END IF;
    IF TRIM(p_cObservacion) IS NULL THEN P_ERROR('Debe indicar la observacion (p_cObservacion)'); END IF;
  
    SELECT COUNT(1) 
  INTO nCant 
  FROM ACSELX.CERTIFICADO 
  WHERE IdePol = p_nIdepol 
  AND NumCert = p_nNumCert;
    
  IF nCant = 0 THEN
      P_ERROR('No existe el certificado '||p_nIdepol||'/'||p_nNumCert||' en ACSELX.CERTIFICADO');
    END IF;
    FIN_PASO;
  END VALIDAR_PARAMETROS;

  -- ************************************************************************************************
  --                                          FORMA FIN00010
  -- ************************************************************************************************

  -- ================================================================================================
  -- 01. [FIN00010 | FORMA | WHEN-NEW-FORM-INSTANCE]
  --     Muestra_Inicio_Formulario; :C00.nNumSesion := USERENV('SessionId');
  --     (FIN00001 abre FIN00010 con LR_Invocar_Proceso_Financ y P_cAccion = 'NUEVO' -> GO_BLOCK('B01_Q'))
  -- ================================================================================================
  PROCEDURE F10_INICIO_FORMA IS
  BEGIN
    INICIO_PASO('01.FIN00010 INICIO','FIN00010 | FORMA | WHEN-NEW-FORM-INSTANCE | P6');
    gC00_10.nNumSesion    := USERENV('SessionId');            -- :C00.nNumSesion
    gC00_10.cIndPolTransc := NULL;
    gC00_10.nNumOperMacsi := NULL;
    gIdSession            := NULL;                             -- :B01_Q.IdSession
    gB03_2.nNumRefinanc   := NULL;
    gB03_2.nNumOper       := NULL;
    FIN_PASO(':C00.nNumSesion = '||gC00_10.nNumSesion);
  END F10_INICIO_FORMA;

  -- ================================================================================================
  -- 02. [FIN00010 | B01_Q.BT_DOC | WHEN-BUTTON-PRESSED]  boton "Doc"
  -- ================================================================================================
  PROCEDURE F10_BT_DOC IS
  BEGIN
    INICIO_PASO('02.BT_DOC','FIN00010 | B01_Q.BT_DOC | WHEN-BUTTON-PRESSED');
    gIdSession := ACSELX.PR_Cond_Financiamiento2.Nuevo_IdSession_Oper_Refinanc(gIdSession);
    gB02_1 := NULL;
    FIN_PASO(':B01_Q.IdSession = '||gIdSession);
  END F10_BT_DOC;

  -- ================================================================================================
  -- 03. [FIN00010 | B02_1.NUMFACT | WHEN-VALIDATE-ITEM] -> unidad FR_Validar_Numero_Factura
  -- ================================================================================================
  PROCEDURE F10_FR_VALIDAR_NUMERO_FACTURA IS
    F  ACSELX.FACTURA%ROWTYPE;
  BEGIN
    INICIO_PASO('03.NUMFACT','FIN00010 | B02_1.NUMFACT | WHEN-VALIDATE-ITEM | P35 | FR_Validar_Numero_Factura');
    F := ACSELX.PR_Factura.Datos_Factura_NumFact(p_nNumFact);
    IF F.NumFact IS NOT NULL THEN
      gB02_1.NumFact       := F.NumFact;
      gB02_1.NumId         := F.NumId;
      gB02_1.CodMoneda     := F.CodMoneda;
      gB02_1.MtoFactMoneda := F.MtoFactMoneda;
      gB02_1.StsFact       := F.StsFact;
      gB02_1.TipoDoc       := F.TipoDoc;
      gB02_1.NumOper       := F.NumOper;
      gB02_1.IdeFact       := F.IdeFact;
    ELSE
      P_ERROR('Este documento no existe ! ('||p_nNumFact||')');
    END IF;
    gB02_1.IdSession := gIdSession;
    IF gB02_1.NumOper IS NULL THEN
      P_ERROR('El documento no tiene numero de operacion, este no se puede financiar');
    END IF;
    P_LOG('Documento '||gB02_1.TipoDoc||' '||gB02_1.NumFact||' IdeFact '||gB02_1.IdeFact||' Estado '||gB02_1.StsFact||
          ' '||gB02_1.CodMoneda||' '||gB02_1.MtoFactMoneda||' NumOper '||gB02_1.NumOper||' Resp.NumId '||gB02_1.NumId);

    -- FR_Commit_Form del bloque B02_1 (base table ACSELX.TEMP_DOCS_FINANC)
    INSERT INTO ACSELX.TEMP_DOCS_FINANC (IdSession, NumFact, NumId, NumOper, IdeFact)
    VALUES (gB02_1.IdSession, gB02_1.NumFact, gB02_1.NumId, gB02_1.NumOper, gB02_1.IdeFact);
    FIN_PASO('Grabado en ACSELX.TEMP_DOCS_FINANC (IdSession '||gIdSession||')');
  END F10_FR_VALIDAR_NUMERO_FACTURA;

  -- ================================================================================================
  -- 04a. [FIN00010 | unidad FR_VALIDA_PLAN_DINAMICO] (RTC 312870) - recorre B02_1
  -- ================================================================================================
  PROCEDURE F10_FR_VALIDA_PLAN_DINAMICO IS
  BEGIN
    P_LOG('Unidad FR_VALIDA_PLAN_DINAMICO');
    IF ACSELX.PR.Busca_Lval('PLANDINA','SWITCH1') = kSi THEN
      IF ACSELX.PR_INTERFASE_AX_SAS2.Valida_Docs_Cobro_X_Plan(gB02_1.NumOper) <> 0 THEN
        P_ERROR('Este documento pertenece a un Plan Dinamico de Pago por Kilometro');
      END IF;
    END IF;
  END F10_FR_VALIDA_PLAN_DINAMICO;

  -- ================================================================================================
  -- 04b. [FIN00010 | unidad FR_Validar_Resp_Pago_Facturas] - recorre B02_1 (un solo documento)
  -- ================================================================================================
  PROCEDURE F10_FR_VALIDAR_RESP_PAGO_FACT IS
  BEGIN
    P_LOG('Unidad FR_Validar_Resp_Pago_Facturas');
    IF gB02_1.NumFact IS NULL THEN
      P_ERROR('No hay documentos en gB02_1.NumFact'); -- la forma hace DELETE_RECORD de filas vacias
    END IF;
  END F10_FR_VALIDAR_RESP_PAGO_FACT;

  -- ================================================================================================
  -- 04c. [FIN00010 | unidad PR_VALIDACION_FINAN]
  -- ================================================================================================
  PROCEDURE F10_PR_VALIDACION_FINAN IS
    v_Existe    NUMBER;
    v_ExisteAnu NUMBER;
  BEGIN
    P_LOG('Unidad PR_VALIDACION_FINAN');
    FOR r IN (SELECT COND.NumRefracc, COND.NumRefinanc, COND.NumOper
              FROM   ACSELX.COND_FINANCIAMIENTO COND
              WHERE  COND.StsFin = 'FRA'
                AND  EXISTS (SELECT 1 FROM ACSELX.FACTURA F WHERE F.NumOper = COND.NumOper)
                AND  COND.NumFinanc IN (SELECT GF.NumFinanc
                                        FROM   ACSELX.GIROS_FINANCIAMIENTO GF
                                        WHERE  GF.NumAcre IN (SELECT A.NumAcre
                                                              FROM   ACSELX.ACREENCIA A
                                                              WHERE  A.IdeFact IN (SELECT TF.IdeFact
                                                                                   FROM   ACSELX.TEMP_DOCS_FINANC TF
                                                                                   WHERE  TF.IdSession = gIdSession)))) LOOP
      IF r.NumRefracc IS NOT NULL THEN
        BEGIN
          SELECT COUNT(1) INTO v_Existe FROM ACSELX.COND_FINANCIAMIENTO WHERE NumRefinanc = r.NumRefracc;
        EXCEPTION WHEN OTHERS THEN v_Existe := 0;
        END;
        BEGIN
          SELECT COUNT(1) INTO v_ExisteAnu FROM ACSELX.COND_FINANCIAMIENTO
          WHERE  NumRefinanc = r.NumRefracc AND StsFin = 'ANU';
        EXCEPTION WHEN OTHERS THEN v_ExisteAnu := 0;
        END;
        IF v_Existe = 0 THEN
          UPDATE ACSELX.COND_FINANCIAMIENTO SET NumRefracc = NULL WHERE NumOper = r.NumOper;
          P_AVISO('NumRefracc '||r.NumRefracc||' inexistente: liberado NumOper '||r.NumOper);
        END IF;
        IF v_ExisteAnu > 0 THEN
          UPDATE ACSELX.COND_FINANCIAMIENTO SET NumRefracc = NULL WHERE NumOper = r.NumOper;
          P_AVISO('NumRefracc '||r.NumRefracc||' anulado: liberado NumOper '||r.NumOper);
        END IF;
      END IF;
    END LOOP;
  END F10_PR_VALIDACION_FINAN;

  -- ================================================================================================
  -- 04d. Consulta de B03_1: FR_Refrescar_Bloque('B03_1', FR_Where_Cond_Financ)
  -- ================================================================================================
  PROCEDURE F10_CONSULTAR_B03_1 IS
    i       PLS_INTEGER := 0;
    P       ACSELX.POLIZA%ROWTYPE;
    C       ACSELX.CLIENTE%ROWTYPE;
    nGastos ACSELX.TOTAL_FINANC.MtoTotCpto%TYPE;
  BEGIN
    P_LOG('Unidad FR_Where_Cond_Financ + B03_1 POST-QUERY');
    gB03_1.DELETE;
    FOR cf IN (SELECT CF.NumFinanc, CF.NumOper, CF.IdePol, CF.NumCert, CF.TipoFin, CF.CodPlan, CF.ModPlan,
                      CF.CodMoneda, CF.TipoId, CF.NumId, CF.DvId, CF.MtoPago, CF.MtoNetoFrac, CF.NumRefinanc
               FROM   ACSELX.COND_FINANCIAMIENTO CF
               WHERE  CF.NumRefracc IS NULL
                 AND  CF.StsFin = 'FRA'
                 AND  EXISTS (SELECT 1 FROM ACSELX.FACTURA F WHERE F.NumOper = CF.NumOper)
                 AND  CF.NumFinanc IN (SELECT GF.NumFinanc
                                       FROM   ACSELX.GIROS_FINANCIAMIENTO GF
                                       WHERE  GF.NumAcre IN (SELECT A.NumAcre
                                                             FROM   ACSELX.ACREENCIA A
                                                             WHERE  A.IdeFact IN (SELECT TF.IdeFact
                                                                                  FROM   ACSELX.TEMP_DOCS_FINANC TF
                                                                                  WHERE  TF.IdSession = gIdSession)))
               ORDER  BY CF.NumOper, CF.NumFinanc) LOOP
      i := i + 1;
      gB03_1(i).NumFinanc := cf.NumFinanc;  gB03_1(i).NumOper  := cf.NumOper;  gB03_1(i).IdePol  := cf.IdePol;
      gB03_1(i).NumCert   := cf.NumCert;    gB03_1(i).TipoFin  := cf.TipoFin;  gB03_1(i).CodPlan := cf.CodPlan;
      gB03_1(i).ModPlan   := cf.ModPlan;    gB03_1(i).CodMoneda:= cf.CodMoneda;gB03_1(i).TipoId  := cf.TipoId;
      gB03_1(i).NumId     := cf.NumId;      gB03_1(i).DvId     := cf.DvId;     gB03_1(i).MtoPago := cf.MtoPago;
      gB03_1(i).MtoNetoFrac := cf.MtoNetoFrac; gB03_1(i).NumRefinanc := cf.NumRefinanc;
      gB03_1(i).cSeleccion := kNo;

      ---- POST-QUERY ----
      P := ACSELX.PR_Poliza.Datos_Poliza(cf.IdePol);
      gB03_1(i).nNumPol  := P.NumPol;
      gB03_1(i).cCodProd := P.CodProd;
      IF cf.IdePol IS NOT NULL THEN
        gB03_1(i).cCodCia := P.CodCia;
      ELSE
        BEGIN
          SELECT PO.CodCia INTO gB03_1(i).cCodCia
          FROM   ACSELX.POLIZA PO
          WHERE  EXISTS (SELECT 1 FROM ACSELX.OPER_POL WHERE NumOper = cf.NumOper AND IdePol = PO.IdePol)
          GROUP  BY PO.CodCia;
        EXCEPTION WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN gB03_1(i).cCodCia := NULL;
        END;
      END IF;
      BEGIN
        SELECT PIP.CodInter INTO gB03_1(i).cCodInter
        FROM   ACSELX.PART_INTER_POL PIP
        WHERE  PIP.IndLider = 'S'
          AND  EXISTS (SELECT 1 FROM ACSELX.OPER_POL WHERE IdePol = PIP.IdePol AND NumOper = cf.NumOper)
        GROUP  BY PIP.CodInter;
      EXCEPTION WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN gB03_1(i).cCodInter := NULL;
      END;
      C := ACSELX.PR_Tercero.Datos_Cliente_Tercero(cf.TipoId, cf.NumId, cf.DvId);
      IF C.CodCli IS NOT NULL THEN
        gB03_1(i).cCodCli := C.CodCli;
      ELSE
        P_AVISO('RESPONSABLE DE PAGO INVALIDO '||cf.IdePol);
      END IF;
      BEGIN
        SELECT NVL(SUM(DG.MtoDetGiroMoneda),0), NVL(SUM(GF.MtoComGiro),0)
        INTO   gB03_1(i).nMtoOper, gB03_1(i).nMtoComOper
        FROM   ACSELX.DET_GIRO_FIN DG, ACSELX.GIROS_FINANCIAMIENTO GF
        WHERE  GF.NumFinanc = cf.NumFinanc AND GF.StsGiro = 'ACT'
          AND  DG.NumFinanc = GF.NumFinanc AND DG.NumGiro = GF.NumGiro
          AND  DG.CodCptoAcre IN ('RECIBO','ALORIM');
      EXCEPTION WHEN OTHERS THEN P_ERROR('No Existe Giros para el Financiamiento: '||cf.NumFinanc);
      END;
      BEGIN
        SELECT NVL(SUM(GF.MtoGiroForaneo),0) INTO gB03_1(i).nMtoPendiente
        FROM   ACSELX.GIROS_FINANCIAMIENTO GF
        WHERE  GF.NumFinanc = cf.NumFinanc AND GF.StsGiro = 'ACT';
      EXCEPTION WHEN OTHERS THEN P_ERROR('No Existe Giros para el Financiamiento: '||cf.NumFinanc);
      END;
      BEGIN
        SELECT NVL(SUM(DG.MtoDetGiroMoneda),0) INTO gB03_1(i).nMtoCob
        FROM   ACSELX.DET_GIRO_FIN DG, ACSELX.GIROS_FINANCIAMIENTO GF
        WHERE  GF.NumFinanc = cf.NumFinanc AND GF.StsGiro = 'COB'
          AND  DG.NumFinanc = GF.NumFinanc AND DG.NumGiro = GF.NumGiro
          AND  DG.CodCptoAcre IN ('RECIBO','ALORIM');
      EXCEPTION WHEN OTHERS THEN P_ERROR('Error en SUM de cobrados '||SQLERRM);
      END;
      IF ACSELX.PR.Busca_Lval('PLANDINA','SWITCH1') = kSi THEN                       -- RTC 312870
        IF ACSELX.PR_INTERFASE_AX_SAS2.Valida_Docs_Cobro_X_Plan(cf.NumOper) <> 0 THEN
          P_ERROR('Este documento pertenece a un Plan Dinamico de Pago por Kilometro');
        END IF;
      END IF;
      SELECT SUM(MtoTotCpto) INTO nGastos
      FROM   ACSELX.TOTAL_FINANC
      WHERE  NumFinanc = cf.NumFinanc AND CodCptoAcre IN ('GTOEMI','IMPIVA');
      gB03_1(i).nPrimaTotal := NVL(nGastos,0) + NVL(cf.MtoNetoFrac,0);

      P_LOG('B03_1('||i||') Financ '||cf.NumFinanc||' Oper '||cf.NumOper||' Poliza '||gB03_1(i).cCodProd||'-'||
            gB03_1(i).nNumPol||' (IdePol '||cf.IdePol||') Cert '||NVL(TO_CHAR(cf.NumCert),'-')||' Resp '||
            gB03_1(i).cCodCli||' Inter '||gB03_1(i).cCodInter||' Pend '||gB03_1(i).nMtoOper||
            ' Cobrado '||gB03_1(i).nMtoCob||' '||cf.CodMoneda);
    END LOOP;

    -- ---- B03_1 PRE-BLOCK P53 ----
    IF gB03_2.cTipoFinanc IS NULL THEN
      gB03_2.cTipoFinanc := 'CUP';
    END IF;

    IF gB03_1.COUNT = 0 THEN
      FOR d IN (SELECT DISTINCT CF.NumFinanc, CF.StsFin, CF.NumRefracc, CF.IdePol, CF.NumCert
                FROM   ACSELX.COND_FINANCIAMIENTO CF, ACSELX.GIROS_FINANCIAMIENTO G, ACSELX.ACREENCIA A
                WHERE  A.IdeFact = gB02_1.IdeFact AND G.NumAcre = A.NumAcre AND CF.NumFinanc = G.NumFinanc) LOOP
        P_AVISO('Financ '||d.NumFinanc||' poliza '||d.IdePol||' cert '||d.NumCert||' StsFin='||d.StsFin||
                ' NumRefracc='||NVL(TO_CHAR(d.NumRefracc),'-'));
      END LOOP;
      P_ERROR('La consulta de FIN00010 no devuelve financiamientos para el documento (deben estar StsFin=FRA, '||
              'sin NumRefracc y con facturas): puede estar anulado, cobrado o ya refinanciado');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -54 THEN
        P_ERROR('El financiamiento esta bloqueado por otra sesion (abierto en FIN00010/FIN00012)');
      END IF;
      RAISE;
  END F10_CONSULTAR_B03_1;

  -- ================================================================================================
  -- 04. [FIN00010 | B02_2.BT_ACEPTAR | WHEN-BUTTON-PRESSED]
  -- ================================================================================================
  PROCEDURE F10_BT_ACEPTAR_DOCUMENTOS IS
  BEGIN
    INICIO_PASO('04.BT_ACEPTAR DOC','FIN00010 | B02_2.BT_ACEPTAR | WHEN-BUTTON-PRESSED | P39');
    F10_FR_VALIDA_PLAN_DINAMICO;
    F10_FR_VALIDAR_RESP_PAGO_FACT;

    P_LOG('Unidad FR_Iniciar_Operacion_Refinanc');
    gB03_2.nTotMtoOper      := 0;
    gB03_2.nTotComiOper     := 0;
    gB03_2.nTotMtoPendiente := 0;
    gB03_2.nMtoTotalNeto    := 0;
    gB03_2.nMtoTotalPrima   := 0;
    gB03_2.nMtoTotalFinanc  := 0;
    gB03_2.cCodMonedaAnt    := NULL;
    gB03_2.dFecEmi          := SYSDATE;
    ACSELX.PR_Cond_Financiamiento2.Anular_Operacion_Refinanc(gB03_2.nNumOper, gB03_2.nNumRefinanc);
    IF gB03_2.nNumRefinanc IS NULL THEN
      gB03_2.nNumRefinanc := ACSELX.PR_Cond_Financiamiento2.Nuevo_Numero_Refinanc;
    END IF;
    P_LOG(':B03_2.nNumRefinanc = '||gB03_2.nNumRefinanc);
    F10_PR_VALIDACION_FINAN;
    F10_CONSULTAR_B03_1;
    FIN_PASO('Financiamientos consultados en B03_1: '||gB03_1.COUNT);
  END F10_BT_ACEPTAR_DOCUMENTOS;

  -- ================================================================================================
  -- 05a. [FIN00010 | unidad FR_Verificar_Transcripcion]
  -- ================================================================================================
  PROCEDURE F10_FR_VERIFICAR_TRANSCRIPCION(i PLS_INTEGER) IS
    cCodGrupo  ACSELX.GRUPO_USUARIO.CodGrpUsr%TYPE;
    U          ACSELX.USUARIO%ROWTYPE := ACSELX.PR_Usuario.Datos_Usuario(USER);
  BEGIN
    IF gB03_2.cIndTranscripcion IS NULL THEN
      BEGIN
        SELECT Perfil INTO cCodGrupo FROM ACSELX.POLIZAS_TRANSCRITAS WHERE IdePol = gB03_1(i).IdePol;
      EXCEPTION WHEN NO_DATA_FOUND THEN cCodGrupo := NULL;
      END;
      IF cCodGrupo IS NOT NULL THEN
        IF U.CodGrpUsr = cCodGrupo THEN gB03_2.cIndTranscripcion := kSi;
        ELSE gB03_2.cIndTranscripcion := kNo;
        END IF;
      ELSE
        -- :B03_3.nNumOper = :B03_1.NumOper
        IF ACSELX.PR.Existe(' ACSELX.OPER_POL_ACSEL_MACSI ',' NumOper = '||NVL(gB03_1(i).NumOper,0)) = 1 THEN
          gB03_2.cIndTranscripcion := kSi;
        ELSE
          gB03_2.cIndTranscripcion := kNo;
        END IF;
        IF U.CodGrpUsr IS NOT NULL THEN
          IF U.CodGrpUsr <> 'TRANSCRI' THEN gB03_2.cIndTranscripcion := kNo; END IF;
        ELSE
          P_ERROR('Usuario '||USER||' no existe en el sistema ');
        END IF;
      END IF;
    END IF;
    IF gB03_2.cIndTranscripcion = kSi THEN
      gC00_10.cIndPolTransc := kSi;
      -- La transcripcion MACSI continua en la forma MIGREFMACSI (LR_INVOCAR_MIG_REFINANC_MACSI): no se replica
      P_ERROR('La poliza es transcrita (MACSI). Este refinanciamiento debe hacerse desde FIN00010');
    ELSE
      gC00_10.cIndPolTransc := kNo;
    END IF;
  END F10_FR_VERIFICAR_TRANSCRIPCION;

  -- ================================================================================================
  -- 05b. [FIN00010 | unidad FR_Validar_Polizas]  RETURN 'S' = hay error (FR_Mensaje + RETURN('S'))
  -- ================================================================================================
  FUNCTION F10_FR_VALIDAR_POLIZAS(i PLS_INTEGER, p_cMsg OUT VARCHAR2) RETURN VARCHAR2 IS
    cConFP       VARCHAR2(1);
    cIndFactPend ACSELX.PLAN_FINANCIAMIENTO.IndFactPend%TYPE;
    cTipoFinFP   VARCHAR2(3);
    cIndDS       VARCHAR2(3);
    nConDS       NUMBER;
    nSinDS       NUMBER;
    cExiste      VARCHAR2(1);
    cValida      VARCHAR2(1) := kNo;
    r            tB03_1 := gB03_1(i);
  BEGIN
    -- Facturas pendientes (si no es transcriptor)
    IF gB03_2.cIndTranscripcion = kNo THEN
      BEGIN
        SELECT kSi INTO cConFP
        FROM   ACSELX.FACTURA
        WHERE  NumOper = r.NumOper
          AND  StsFact||'' = 'INC'
          AND  ((TipoDocPag IS NOT NULL AND NumDoc IS NOT NULL AND Serie IS NOT NULL) OR (IndFactPend = 'S'))
          AND  TipoId = r.TipoId AND NumId = r.NumId AND DvId = r.DvId;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN cConFP := kNo;
        WHEN TOO_MANY_ROWS THEN cConFP := kSi;
      END;
    ELSE
      cConFP := kNo;
    END IF;
    IF cConFP = kSi THEN
      BEGIN
        SELECT NVL(IndFactPend,'N'), TipoFinFactPend INTO cIndFactPend, cTipoFinFP
        FROM   ACSELX.PLAN_FINANCIAMIENTO WHERE CodPlan = r.CodPlan AND ModPlan = r.ModPlan;
      EXCEPTION WHEN NO_DATA_FOUND THEN cIndFactPend := kNo; cTipoFinFP := NULL;
      END;
      IF cIndFactPend = kNo THEN
        p_cMsg := 'El tipo de financiamiento '||r.CodPlan||' no permite refinanciar con Facturas Pendientes';
        RETURN kSi;
      END IF;
    ELSE
      cTipoFinFP := NULL;
    END IF;
    IF gB03_2.cFinFactPend IS NULL THEN
      IF cConFP = kSi THEN gB03_2.cFinFactPend := kSi; gB03_2.cTipoFinFP := cTipoFinFP;
      ELSE gB03_2.cFinFactPend := kNo;
      END IF;
    ELSE
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN
        IF cConFP = kSi THEN gB03_2.cFinFactPend := kSi; gB03_2.cTipoFinFP := cTipoFinFP;
        ELSE gB03_2.cFinFactPend := kNo;
        END IF;
      END IF;
      IF gB03_2.cFinFactPend = kSi THEN
        IF cConFP = kNo THEN
          p_cMsg := 'Se va a refinanciar con Facturas Pendientes. No se puede financiar otro tipo de documentos';
          RETURN kSi;
        ELSIF cTipoFinFP != gB03_2.cTipoFinFP THEN
          p_cMsg := 'Financiamiento con facturas pendientes tiene configurado diferente Tipo de Financiamiento al original';
          RETURN kSi;
        END IF;
      ELSIF cConFP = kSi THEN
        p_cMsg := 'No se esta financiando Facturas Pendientes y este documento si las tiene.';
        RETURN kSi;
      END IF;
    END IF;
    -- Refinanciamiento individual o en grupo
    IF gB03_2.cIndGrupo IS NULL THEN
      IF NVL(r.nMtoCob,0) > 0 THEN gB03_2.cIndGrupo := kNo; ELSE gB03_2.cIndGrupo := kSi; END IF;
    ELSE
      IF NVL(r.nMtoCob,0) > 0 THEN
        IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN
          gB03_2.cIndGrupo := kNo;
        ELSIF (gB03_2.cIndGrupo = kSi OR NVL(gB03_2.nTotMtoOper,0) > 0) AND NVL(r.cSeleccion,'N') = kNo THEN
          p_cMsg := 'Poliza tiene documentos cobrados. No puede ser refinanciado en grupo';
          RETURN kSi;
        END IF;
      ELSE
        IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN
          gB03_2.cIndGrupo := kSi;
        ELSIF gB03_2.cIndGrupo = kNo THEN
          p_cMsg := 'Se va a realizar refinanciamiento individual. No se puede seleccionar mas polizas';
          RETURN kSi;
        END IF;
      END IF;
    END IF;
    -- Mismo responsable de pago
    IF gB03_2.cCodCliAnt IS NULL THEN gB03_2.cCodCliAnt := r.cCodCli; END IF;
    IF gB03_2.cCodCliAnt != r.cCodCli THEN
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN gB03_2.cCodCliAnt := r.cCodCli;
      ELSE p_cMsg := 'No puede seleccionar Operaciones con responsables de pago diferentes.'; RETURN kSi;
      END IF;
    END IF;
    -- Mismo intermediario
    IF gB03_2.cCodInterAnt IS NULL THEN gB03_2.cCodInterAnt := r.cCodInter; END IF;
    IF gB03_2.cCodInterAnt != r.cCodInter THEN
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN gB03_2.cCodInterAnt := r.cCodInter;
      ELSE p_cMsg := 'No puede seleccionar Operaciones con intermediarios diferentes.'; RETURN kSi;
      END IF;
    END IF;
    -- Misma moneda
    IF gB03_2.cCodMonedaAnt IS NULL THEN gB03_2.cCodMonedaAnt := r.CodMoneda; END IF;
    IF gB03_2.cCodMonedaAnt != r.CodMoneda THEN
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN gB03_2.cCodMonedaAnt := r.CodMoneda;
      ELSE p_cMsg := 'No puede seleccionar Operaciones con monedas diferentes.'; RETURN kSi;
      END IF;
    END IF;
    -- Documentos con y sin documento SUNAT (N3025082)
    BEGIN
      SELECT COUNT(1) INTO nConDS FROM ACSELX.FACTURA
      WHERE  StsFact||'' = 'INC'
        AND  ((NumDoc IS NOT NULL AND Serie IS NOT NULL) OR NVL(IndFactPend,'N') = 'S')
        AND  IdeFact IN (SELECT A.IdeFact FROM ACSELX.ACREENCIA A
                         WHERE A.NumAcre IN (SELECT G.NumAcre FROM ACSELX.GIROS_FINANCIAMIENTO G
                                             WHERE G.NumFinanc = r.NumFinanc));
    EXCEPTION WHEN OTHERS THEN nConDS := 0;
    END;
    BEGIN
      SELECT COUNT(1) INTO nSinDS FROM ACSELX.FACTURA
      WHERE  StsFact||'' = 'INC' AND NumDoc IS NULL AND Serie IS NULL AND NVL(IndFactPend,'N') = 'N'
        AND  IdeFact IN (SELECT A.IdeFact FROM ACSELX.ACREENCIA A
                         WHERE A.NumAcre IN (SELECT G.NumAcre FROM ACSELX.GIROS_FINANCIAMIENTO G
                                             WHERE G.NumFinanc = r.NumFinanc));
    EXCEPTION WHEN OTHERS THEN nSinDS := 0;
    END;
    IF nConDS > 0 AND nSinDS > 0 THEN
      p_cMsg := 'La Operacion posee registros con y sin documento SUNAT a la vez. No se puede Refinanciar.';
      RETURN kSi;
    ELSIF nConDS > 0 AND nSinDS = 0 THEN cIndDS := kSi;
    ELSIF nConDS = 0 AND nSinDS > 0 THEN cIndDS := kNo;
    END IF;
    IF gB03_2.cIndDSAnt IS NULL THEN gB03_2.cIndDSAnt := cIndDS; END IF;
    IF gB03_2.cIndDSAnt != cIndDS THEN
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN gB03_2.cIndDSAnt := cIndDS;
      ELSE p_cMsg := 'No pueden seleccionar registros con y sin documento SUNAT a la vez.'; RETURN kSi;
      END IF;
    END IF;
    -- Misma compania
    IF gB03_2.cCodCiaAnt IS NULL THEN 
     gB03_2.cCodCiaAnt := r.cCodCia; 
  END IF;
    
  IF gB03_2.cCodCiaAnt != r.cCodCia THEN
      IF NVL(gB03_2.nTotMtoOper,0) = 0 THEN 
       gB03_2.cCodCiaAnt := r.cCodCia;
      ELSE
       p_cMsg := 'No puede seleccionar Operaciones de companias diferentes.'; RETURN kSi;
      END IF;
    END IF;
    -- Exclusion por responsable de pago (N3034814)
    BEGIN
      SELECT DISTINCT kSi 
    INTO cExiste
      FROM   ACSELX.CONF_EXCL_REPOSITORIO
      WHERE  (NumId, CodProd, TipoDoc) IN
             (SELECT r.NumId, r.cCodProd, F.TipoDoc
              FROM   ACSELX.FACTURA F
              WHERE  F.IdeFact IN (SELECT A.IdeFact FROM ACSELX.ACREENCIA A
                                   WHERE A.NumAcre IN (SELECT G.NumAcre FROM ACSELX.GIROS_FINANCIAMIENTO G
                                                       WHERE G.NumFinanc = r.NumFinanc)))
        AND  StsExcl = 'ACT' 
    AND TipoReg = 'EXC' 
    AND TipoExc = 'RSP';

    EXCEPTION 
    WHEN OTHERS THEN 
      cExiste := kNo;
    END;

    IF cExiste = kSi THEN
      BEGIN
        SELECT DISTINCT kSi 
    INTO cExiste
        FROM   ACSELX.CONF_EXCL_REPOSITORIO
        WHERE  CodProd = r.cCodProd 
    AND NumPol = r.nNumPol
        AND  StsExcl = 'ACT' 
    AND TipoReg = 'INC' 
    AND TipoExc = 'RSP';
      EXCEPTION 
      WHEN OTHERS THEN 
      cExiste := kNo;
      END;

      IF cExiste = kNo THEN
        cExiste := ACSELX.PR_Acceso_Usuario.Existe_OperUsuario(USER,'392');
        IF cExiste = kNo THEN
          p_cMsg := 'No esta autorizado para realizar el Financiamiento de los documentos de esta poliza. '||
                    'La poliza esta excluida del financiamiento por pertenecer a su responsable de pago';
          RETURN kSi;
        END IF;
      END IF;
    END IF;
    -- Componente facultativo (N3035516)
    cValida := ACSELX.PR_REFINAN_MASIVO.FR_Valida_Facultativo(r.NumFinanc);
    IF cValida = kSi THEN
      cValida := ACSELX.PR_Acceso_Usuario.Existe_OperUsuario(USER,'404');
      IF cValida = kNo THEN
        p_cMsg := 'No esta autorizado para realizar el Financiamiento de Polizas con componente Facultativo.';
        RETURN kSi;
      END IF;
      P_ERROR('Usted va a Financiar una Poliza Facultativa (en la forma se confirma con "Ok"); NumFinanc =>'||r.NumFinanc);
    END IF;
    RETURN kNo;
  END F10_FR_VALIDAR_POLIZAS;

  -- ================================================================================================
  -- 05c. [FIN00010 | unidad FR_Sumar_Montos_Totales]
  -- ================================================================================================
  PROCEDURE F10_FR_SUMAR_MONTOS_TOTALES(i PLS_INTEGER) IS
  BEGIN
    gB03_2.nTotMtoOper      := NVL(gB03_2.nTotMtoOper,0)      + NVL(gB03_1(i).nMtoOper,0);
    gB03_2.nTotComiOper     := NVL(gB03_2.nTotComiOper,0)     + NVL(gB03_1(i).nMtoComOper,0);
    gB03_2.nTotMtoPendiente := NVL(gB03_2.nTotMtoPendiente,0) + NVL(gB03_1(i).nMtoPendiente,0);
    gB03_2.nMtoTotalNeto    := NVL(gB03_2.nMtoTotalNeto,0)    + NVL(gB03_1(i).MtoNetoFrac,0);
    gB03_2.nMtoTotalPrima   := NVL(gB03_2.nMtoTotalPrima,0)   + NVL(gB03_1(i).nPrimaTotal,0);
    gB03_2.nMtoTotalFinanc  := NVL(gB03_2.nMtoTotalFinanc,0)  + NVL(gB03_1(i).MtoPago,0);
    gB03_1(i).cSeleccion    := kSi;
  END F10_FR_SUMAR_MONTOS_TOTALES;

  -- ================================================================================================
  -- 05d. [FIN00010 | unidad FR_Procesar_Operacion]
  -- ================================================================================================
  PROCEDURE F10_FR_PROCESAR_OPERACION(i PLS_INTEGER, p_cIndSel VARCHAR2, p_cIndTrans VARCHAR2) IS
    O  ACSELX.OPER_POL_TRANS%ROWTYPE;
    M  MIG_TEMP_REFIN%ROWTYPE;
  BEGIN
    IF gB03_2.nNumOper IS NULL THEN
      gB03_2.nNumOper := ACSELX.PR_COND_FINANCIAMIENTO.OPER_REFRACC(gB03_2.nNumRefinanc);
      P_LOG('Operacion REFRA creada: :B03_2.nNumOper = '||gB03_2.nNumOper);
    END IF;
    O.IdePol      := gB03_1(i).IdePol;
    O.NumCert     := gB03_1(i).NumCert;
    O.NumOper     := gB03_2.nNumOper;
    O.FecMov      := SYSDATE;
    O.MtoOper     := gB03_1(i).nMtoOper;
    O.TipoOp      := 'REM';
    O.NumOperOrig := gB03_1(i).NumOper;
    M.NumSesion   := gC00_10.nNumSesion;
    M.NumPol      := gB03_1(i).nNumPol;
    M.CodProd     := gB03_1(i).cCodProd;
    M.MtoPrima    := gB03_1(i).MtoPago;
    BEGIN
      ACSELX.PR_Cond_Financiamiento2.Procesar_Transaccion_Financ(p_cIndSel, p_cIndTrans, gB03_1(i).NumFinanc,
                                                                 gB03_2.nNumRefinanc, O, M);
    EXCEPTION
      WHEN OTHERS THEN P_ERROR('Error Procesar_Transaccion_Financ:'||SQLERRM);
    END;
    P_LOG('FR_Procesar_Operacion('||p_cIndSel||') financ '||gB03_1(i).NumFinanc||
          ' -> OPER_POL_TRANS y NumRefracc = '||gB03_2.nNumRefinanc);
  END F10_FR_PROCESAR_OPERACION;

  -- ================================================================================================
  -- 05e. [FIN00010 | unidad FR_Operaciones]
  -- ================================================================================================
  PROCEDURE F10_FR_OPERACIONES(i PLS_INTEGER, p_cSeleccion VARCHAR2, p_cIndTranscripcion VARCHAR2) IS
    G ACSELX.GIROS_FINANCIAMIENTO%ROWTYPE;
    A ACSELX.ACREENCIA%ROWTYPE;
    nCantAcre NUMBER(5);
    nIdeFactOrig  ACSELX.FACTURA.IdeFact%TYPE;
  BEGIN
    F10_FR_PROCESAR_OPERACION(i, p_cSeleccion, p_cIndTranscripcion);
    G := ACSELX.PR_Cond_Financiamiento2.Datos_Giros_Financ(gB03_1(i).NumFinanc, 1);
    A := ACSELX.PR_Acreencia.Datos_Acreencia(G.NumAcre);
    nCantAcre := ACSELX.PR_Cond_Financiamiento2.Cantidad_Acreencias_x_Factura(A.IdeFact);
    IF nCantAcre > 1 THEN
      nIdeFactOrig := A.IdeFact;
      P_LOG('La factura '||nIdeFactOrig||' tiene '||nCantAcre||' acreencias: se marcan los registros relacionados');
      FOR j IN 1 .. gB03_1.COUNT LOOP
        IF j <> i AND gB03_1(j).NumOper = gB03_1(i).NumOper THEN
          G := ACSELX.PR_Cond_Financiamiento2.Datos_Giros_Financ(gB03_1(j).NumFinanc, 1);
          A := ACSELX.PR_Acreencia.Datos_Acreencia(G.NumAcre);
          IF A.IdeFact = nIdeFactOrig THEN
        P_LOG('p_cSeleccion = '||p_cSeleccion||' , gB03_1(j).cSeleccion '||gB03_1(j).cSeleccion);
            IF p_cSeleccion = kSi AND NVL(gB03_1(j).cSeleccion,'N') = kNo THEN
              F10_FR_SUMAR_MONTOS_TOTALES(j);
            END IF;
            F10_FR_PROCESAR_OPERACION(j, p_cSeleccion, p_cIndTranscripcion);
            P_ERROR('Marcado tambien el financiamiento relacionado '||gB03_1(j).NumFinanc||' (poliza '||
                    gB03_1(j).IdePol||' cert '||gB03_1(j).NumCert||')');
          END IF;
        END IF;
      END LOOP;
    END IF;
  END F10_FR_OPERACIONES;

  -- ================================================================================================
  -- 05. [FIN00010 | B03_1.CSELECCION | WHEN-CHECKBOX-CHANGED]  check "Sel" del certificado
  -- ================================================================================================
  PROCEDURE F10_CSELECCION(i PLS_INTEGER) IS
    cMsg VARCHAR2(500);
  BEGIN
    P_LOG('Check Sel en B03_1('||i||') financ '||gB03_1(i).NumFinanc);
    F10_FR_VERIFICAR_TRANSCRIPCION(i);
    IF F10_FR_VALIDAR_POLIZAS(i, cMsg) = kNo THEN
      F10_FR_SUMAR_MONTOS_TOTALES(i);
    ELSE
      P_ERROR(cMsg); -- en la forma: alerta y el check queda sin marcar
    END IF;
    F10_FR_VERIFICAR_TRANSCRIPCION(i);
    IF gB03_2.cIndTranscripcion = kNo THEN
      IF gB03_1(i).nNumPol IS NOT NULL AND gB03_1(i).IdePol IS NOT NULL THEN
        IF ACSELX.PR_Poliza.Valida_Polizas_Migradas(gB03_1(i).nNumPol, gB03_1(i).IdePol) = 1 THEN
          P_ERROR('Poliza con movimientos pendientes no puede ser refinanciada');
        END IF;
      END IF;
    END IF;
    F10_FR_OPERACIONES(i, gB03_1(i).cSeleccion, gB03_2.cIndTranscripcion);
    IF gB03_2.nTotMtoPendiente = 0 THEN
      IF gB03_2.dFecEmi IS NULL THEN gB03_2.dFecEmi := SYSDATE; END IF;
      gB03_2.cIndTranscripcion := NULL;
    END IF;
    IF gB03_1(i).TipoFin = 'LET' THEN
      IF ACSELX.PR_Cond_Financiamiento2.Existe_Letras_Pendientes(gB03_1(i).NumFinanc) = kSi THEN
        P_ERROR('No se puede Refinanciar, Financiamiento anterior con Letras Pendientes de Aceptar');
      END IF;
    END IF;
  END F10_CSELECCION;

  -- ================================================================================================
  -- 05. Seleccion del certificado (p_nIdepol, p_nNumCert) en B03_1 = lo que hace el usuario en pantalla
  -- ================================================================================================
  PROCEDURE F10_SELECCIONAR_CERTIFICADO IS
    nMarc PLS_INTEGER := 0;
  BEGIN
    INICIO_PASO('05.CHECK SEL','FIN00010 | B03_1.CSELECCION | WHEN-CHECKBOX-CHANGED | P60');
    FOR i IN 1 .. gB03_1.COUNT LOOP
      IF gB03_1(i).IdePol = p_nIdepol AND (gB03_1(i).NumCert = p_nNumCert OR gB03_1(i).NumCert IS NULL)
         AND NVL(gB03_1(i).cSeleccion,'N') = kNo THEN
        IF gB03_1(i).NumCert IS NULL THEN
          P_AVISO('El financiamiento '||gB03_1(i).NumFinanc||' es a nivel de poliza (sin certificado)');
        END IF;
        F10_CSELECCION(i);
        nMarc := nMarc + 1;
      END IF;
    END LOOP;
    IF nMarc = 0 THEN
      P_ERROR('El documento '||p_nNumFact||' no tiene financiamientos refinanciables para la poliza '||
              p_nIdepol||' certificado '||p_nNumCert||' (revise los registros listados en el paso 04)');
    END IF;
    FIN_PASO('Seleccionados: total '||gB03_2.nTotMtoOper||' '||gB03_2.cCodMonedaAnt||' comision '||
             gB03_2.nTotComiOper||' prima total '||gB03_2.nMtoTotalPrima||' NumOper '||gB03_2.nNumOper);
  END F10_SELECCIONAR_CERTIFICADO;

  -- ================================================================================================
  -- 06a. [FIN00010 | unidad PR_VALIDAR_DOC_SUNAT] (N3025082)
  -- ================================================================================================
  PROCEDURE F10_PR_VALIDAR_DOC_SUNAT IS
    nConDS NUMBER;
    nSinDS NUMBER;
  BEGIN
    P_LOG('Unidad PR_VALIDAR_DOC_SUNAT');
    BEGIN
      SELECT COUNT(1) 
    INTO nConDS 
    FROM ACSELX.FACTURA
      WHERE  StsFact||'' = 'INC'
        AND  ((NumDoc IS NOT NULL AND Serie IS NOT NULL) OR NVL(IndFactPend,'N') = 'S')
        AND  IdeFact IN (SELECT IdeFact 
                     FROM ACSELX.ACREENCIA A
                         WHERE A.NumAcre IN (SELECT G.NumAcre 
                                 FROM ACSELX.GIROS_FINANCIAMIENTO G
                                             WHERE G.NumFinanc IN (SELECT NumFinanc 
                                             FROM ACSELX.COND_FINANCIAMIENTO
                                                                   WHERE NumRefracc = gB03_2.nNumRefinanc)));
    EXCEPTION 
    WHEN OTHERS 
      THEN nConDS := 0;
    END;

    BEGIN
      SELECT COUNT(1) 
    INTO nSinDS 
    FROM ACSELX.FACTURA
      WHERE  StsFact||'' = 'INC' 
    AND NumDoc IS NULL 
    AND Serie IS NULL 
    AND NVL(IndFactPend,'N') = 'N'
      AND  IdeFact IN (SELECT IdeFact 
                     FROM ACSELX.ACREENCIA A
                       WHERE A.NumAcre IN (SELECT G.NumAcre 
                                 FROM ACSELX.GIROS_FINANCIAMIENTO G
                                           WHERE G.NumFinanc IN (SELECT NumFinanc 
                                             FROM ACSELX.COND_FINANCIAMIENTO
                                                                 WHERE NumRefracc = gB03_2.nNumRefinanc)));
    EXCEPTION 
     WHEN OTHERS THEN 
       nSinDS := 0;
    END;

    IF nConDS > 0 AND nSinDS > 0 THEN
      P_ERROR('La Operacion posee registros con y sin documento SUNAT a la vez. No se puede Refinanciar.');
    END IF;

  END F10_PR_VALIDAR_DOC_SUNAT;

  -- ================================================================================================
  -- 06b. [FIN00010 | unidad FR_Generar_Resp_Pago]
  -- ================================================================================================
  PROCEDURE F10_FR_GENERAR_RESP_PAGO IS
    cTipoCli          ACSELX.CLIENTE.TipoCli%TYPE;
    cCodPlanFracc     ACSELX.PLAN_FINANCIAMIENTO.CodPlan%TYPE;
    cNumModPlanFracc  ACSELX.PLAN_FINANCIAMIENTO.ModPlan%TYPE;
    nCantCuo          ACSELX.PLAN_FINANCIAMIENTO.NroGiros%TYPE;
    nNumDoc           ACSELX.DOC_PAGO_CLIENTE.NumDoc%TYPE;
    cNumDocRef        ACSELX.DOC_PAGO_CLIENTE.NumDocRef%TYPE;
    cTipoRed          ACSELX.PLAN_FINANCIAMIENTO.TipoRed%TYPE;
    C                 ACSELX.CLIENTE%ROWTYPE;
    T                 ACSELX.TERCERO%ROWTYPE;
    R                 ACSELX.RESP_PAGO_REFRA%ROWTYPE;
    kR                ACSELX.RESP_PAGO_REFRA%ROWTYPE;
  BEGIN
    P_LOG('Unidad FR_Generar_Resp_Pago');
    FOR cr IN (SELECT TipoId, NumId, DvId 
             FROM ACSELX.COND_FINANCIAMIENTO
               WHERE NumRefracc = gB03_2.nNumRefinanc 
         GROUP BY TipoId, NumId, DvId) LOOP
      
    C := ACSELX.PR_TERCERO.Datos_Cliente_Tercero('0', cr.NumId, '0');
      
    IF C.CodCli IS NOT NULL THEN
        IF C.TipoCli = 'J' THEN cTipoCli := 'P'; ELSE cTipoCli := C.TipoCli; END IF;
      ELSE
        P_ERROR('No existe CLIENTE para el codigo indicado (NumId '||cr.NumId||')');
      END IF;
    
      BEGIN
        ACSELX.PR_Cond_Financiamiento2.Obtener_Plan_Financ(gB03_2.cTipoFinanc, cTipoCli, cCodPlanFracc,
                                                           cNumModPlanFracc, nCantCuo);
        IF cCodPlanFracc IS NULL THEN
          P_AVISO('No existe plan de financiamiento para Tipo Financiamiento '||gB03_2.cTipoFinanc||
                  ' y Tipo de Cliente '||cTipoCli);
        END IF;

      EXCEPTION
        WHEN OTHERS THEN 
      cCodPlanFracc := NULL; 
      cNumModPlanFracc := NULL; 
      nCantCuo := NULL;
      END;
      BEGIN
        SELECT NVL(TipoRed,'S') 
    INTO cTipoRed 
    FROM ACSELX.PLAN_FINANCIAMIENTO
        WHERE  CodPlan = cCodPlanFracc 
    AND ModPlan = cNumModPlanFracc;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          cTipoRed := 'S';                                 -- en la forma esta SELECT falla si no hay plan por defecto
          P_AVISO('Sin plan por defecto: TipoRed = S (el plan se asigna en el paso 09)');
      END;

      BEGIN
        SELECT NumDoc, NumDocRef 
    INTO nNumDoc, cNumDocRef
        FROM ACSELX.DOC_PAGO_CLIENTE 
    WHERE CodCli = C.CodCli 
    AND IndDocDef = 'S';
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
      nNumDoc := NULL; 
      cNumDocRef := NULL;
      END;

      T := ACSELX.PR_TERCERO.Datos_Tercero(C.TipoId, C.NumId, C.DvId);
      R := kR;
      R.NumRefinanc     := gB03_2.nNumRefinanc;
      R.CodCli          := C.CodCli;
      R.PorcPago        := 100;
      R.CodPais         := T.CodPais;
      R.Direc           := T.Direc;
      R.CodEstado       := T.CodEstado;
      R.CodCiudad       := T.CodCiudad;
      R.CodMunicipio    := T.CodMunicipio;
      R.Telef1          := T.Telef1;
      R.Telef2          := T.Telef2;
      R.Telef3          := T.Telef3;
      R.Fax             := T.Fax;
      R.Telex           := T.Telex;
      R.Zip             := T.Zip;
      R.CodRuta         := T.ZonaCob;
      R.CodPlanFracc    := cCodPlanFracc;
      R.NumModPlanFracc := cNumModPlanFracc;
      R.CantCuo         := nCantCuo;
      R.NumDocRef       := cNumDocRef;
      R.NumDoc          := nNumDoc;
      R.CodFormCobro    := NULL;
      R.FormFact        := 'PRP';
      R.TipoRed         := cTipoRed;
    
      BEGIN
        ACSELX.PR_Cond_Financiamiento2.CREAR_RESP_PAGO_REFRA(R);
      EXCEPTION 
       WHEN OTHERS THEN 
        P_ERROR('Error al insertar en RESP_PAGO_REFRA '||SQLERRM);
      END;
      P_LOG('RESP_PAGO_REFRA creado con el responsable actual '||C.CodCli||' plan '||NVL(cCodPlanFracc,'-')||
            '-'||cNumModPlanFracc||' cuotas '||nCantCuo);
    END LOOP;
  
    BEGIN
      ACSELX.PR_Cond_Financiamiento2.Distribuir_Porc_Pago_Refra(gB03_2.nNumRefinanc);
    EXCEPTION 
    WHEN OTHERS THEN 
      P_ERROR(' Error:'||SQLERRM);
    
  END;
  END F10_FR_GENERAR_RESP_PAGO;

  -- ================================================================================================
  -- 06. [FIN00010 | B03_1 | KEY-NXTBLK]  PR_VALIDAR_DOC_SUNAT; FR_Entrar_Resp_Pago;
  -- ================================================================================================
  PROCEDURE F10_SIGUIENTE_BLOQUE IS
  BEGIN
    INICIO_PASO('06.KEY-NXTBLK B03_1','FIN00010 | B03_1 | KEY-NXTBLK');
    F10_PR_VALIDAR_DOC_SUNAT;
    P_LOG('Unidad FR_Entrar_Resp_Pago');
    IF gC00_10.cIndPolTransc = kSi THEN
      P_ERROR('Poliza transcrita: no se puede continuar desde el bloque anonimo');
    END IF;
    
  IF ACSELX.PR.Existe(' ACSELX.OPER_POL_TRANS ',' NumOper = '||NVL(gB03_2.nNumOper,0)) = 1 THEN
      IF gB03_2.cFinFactPend = kSi THEN
        P_AVISO('Por politicas las Facturas Pendientes se financiaran en '||
                ACSELX.PR.Busca_Lval('TIPOFIN', gB03_2.cTipoFinFP));
        gB03_2.cTipoFinanc := gB03_2.cTipoFinFP;
      END IF;
      P_AVISO('Se emitira una unica factura por los documentos financiados');
      F10_FR_GENERAR_RESP_PAGO;

      -- LR_Invocar_ReFinanciamiento llama FIN00012
      gC00_12.nNumRefinanc      := gB03_2.nNumRefinanc;      -- p_nNumRefinanc
      gC00_12.nNumOper          := gB03_2.nNumOper;          -- p_nNumOper
      gC00_12.cTipoFinanc       := gB03_2.cTipoFinanc;       -- p_cTipoFinanc
      gC00_12.nTotMtoOper       := gB03_2.nTotMtoOper;       -- p_nTotMtoOper
      gC00_12.nTotComiOper      := gB03_2.nTotComiOper;      -- p_nTotComiOper
      gC00_12.dFecIniVig        := gB03_2.dFecIniVig;        -- p_dFecIniVig (NULL en FIN00010)
      gC00_12.dFecFinVig        := gB03_2.dFecFinVig;        -- p_dFecFinVig (NULL en FIN00010)
      gC00_12.dFecEmi           := gB03_2.dFecEmi;           -- p_dFecEmi
      gC00_12.cCodMonedaAnt     := gB03_2.cCodMonedaAnt;     -- p_cCodMonedaAnt
      gC00_12.nNumOperMacsi     := gC00_10.nNumOperMacsi;    -- p_nNumOperMacsi
      gC00_12.cIndTranscripcion := gB03_2.cIndTranscripcion; -- p_cIndTranscrip
      gC00_12.cIndPolTransc     := gC00_10.cIndPolTransc;    -- p_cIndPolTransc
      gC00_12.cIndFactPend      := gB03_2.cFinFactPend;      -- p_cIndFactPend
      FIN_PASO('LR_Invocar_ReFinanciamiento -> FIN00012 (NumRefinanc '||gC00_12.nNumRefinanc||
               ', NumOper '||gC00_12.nNumOper||', TipoFinanc '||gC00_12.cTipoFinanc||', FecEmi '||
               TO_CHAR(gC00_12.dFecEmi,'dd/mm/yyyy hh24:mi')||')');
    ELSE
      P_ERROR('No hay documentos marcados en OPER_POL_TRANS para la operacion '||gB03_2.nNumOper);
    END IF;
  END F10_SIGUIENTE_BLOQUE;

  -- ************************************************************************************************
  --                                          FORMA FIN00012
  -- ************************************************************************************************

  -- ================================================================================================
  -- 07. [FIN00012 | FORMA | WHEN-NEW-FORM-INSTANCE]  copia los parametros a C00,
  -- ================================================================================================
  PROCEDURE F12_INICIO_FORMA IS
    nCant NUMBER;
  BEGIN

    INICIO_PASO('07.FIN00012 INICIO','FIN00012 | FORMA | WHEN-NEW-FORM-INSTANCE | P6 + B01_1 PRE-BLOCK P12');
    gC00_12.cIndAutoriza := kNo;
    gC00_12.cIndCrear    := kSi;
    
  SELECT COUNT(1) 
  INTO nCant 
  FROM ACSELX.RESP_PAGO_REFRA 
  WHERE NumRefinanc = gC00_12.nNumRefinanc;
    
  IF nCant <> 1 THEN
      P_ERROR('Se esperaba 1 responsable de pago en B01_1 y hay '||nCant||
              ' (los documentos tienen mas de un responsable)');
    END IF;

    SELECT * 
  INTO gB01_1 
  FROM ACSELX.RESP_PAGO_REFRA 
  WHERE NumRefinanc = gC00_12.nNumRefinanc;

  gB01_1Ant    := gB01_1.CodCli;
    gB01_1TipFin := gC00_12.cTipoFinanc;

    FIN_PASO('B01_1: responsable actual '||gB01_1.CodCli||' plan '||gB01_1.CodPlanFracc||'-'||
             gB01_1.NumModPlanFracc||' cuotas '||gB01_1.CantCuo);

  END F12_INICIO_FORMA;

  -- ================================================================================================
  -- 08. [FIN00012 | B01_1.CODCLI | WHEN-VALIDATE-ITEM]  cambio de responsable de pago
  --     Nuevo valor de :B01_1.CodCli = asegurado del certificado (ACSELX.CERTIFICADO.CODCLI)
  -- ================================================================================================
  PROCEDURE F12_CAMBIAR_RESPONSABLE IS
    cCodCli  ACSELX.CERTIFICADO.CodCli%TYPE;
    R        ACSELX.RESP_PAGO_REFRA%ROWTYPE;
    T        ACSELX.TERCERO%ROWTYPE;
    C        ACSELX.CLIENTE%ROWTYPE;
    DR       ACSELX.DESC_RUTA%ROWTYPE;
    D        ACSELX.DOC_PAGO_CLIENTE%ROWTYPE;
    TJ       ACSELX.TARJ_CRED%ROWTYPE;
    E        ACSELX.ENT_FINAN%ROWTYPE;
  BEGIN
    INICIO_PASO('08.CAMBIO RESPONSABLE','FIN00012 | B01_1.CODCLI | WHEN-VALIDATE-ITEM | P27');
    
  SELECT CodCli 
  INTO cCodCli 
  FROM ACSELX.CERTIFICADO 
  WHERE IdePol = p_nIdepol 
  AND NumCert = p_nNumCert;

  IF cCodCli IS NULL THEN
      P_ERROR('El certificado '||p_nIdepol||'/'||p_nNumCert||' no tiene asegurado (CODCLI)');
  END IF;

    P_LOG('Asegurado del certificado '||p_nIdepol||'/'||p_nNumCert||': CODCLI '||cCodCli||
          ' (responsable anterior '||gB01_1Ant||')');

    gB01_1.CodCli := ACSELX.PR.Cliente(cCodCli);
    R := ACSELX.PR_Cond_Financiamiento2.Datos_Resp_Pago_Refra(gC00_12.nNumRefinanc, gB01_1.CodCli);
    C := ACSELX.PR_Cliente.Datos_Cliente(gB01_1.CodCli);
    T := ACSELX.PR_Tercero.Datos_Tercero(C.TipoId, C.NumId, C.DvId);
    IF T.NumId IS NOT NULL THEN
      gB01_1.CodPais       := T.CodPais;
      gB01_1.CodEstado     := T.CodEstado;
      gB01_1.CodCiudad     := T.CodCiudad;
      gB01_1.CodMunicipio  := T.CodMunicipio;
      gB01_1.Direc         := T.Direc;
      gB01_1.Telef1        := T.Telef1;
      gB01_1.Telef2        := T.Telef2;
      gB01_1.Telef3        := T.Telef3;
      gB01_1.Fax           := T.Fax;
      gB01_1.Telex         := T.Telex;
      gB01_1.Zip           := T.Zip;
      gB01_1.CodZonaPostal := T.CodZonaPostal;
      gB01_1.CodRuta       := T.ZonaCob;
    ELSE
      P_ERROR('No existe CLIENTE/TERCERO para el codigo indicado ('||gB01_1.CodCli||')');
    END IF;
    gCliAseg := C;
    -- PR_Ubigeo.Busca_Ubigeo: solo descripciones de pantalla (no se replica)
    DR := ACSELX.PR_Cobrador.Datos_Desc_Ruta(gB01_1.CodRuta);
    IF DR.DescRuta IS NOT NULL THEN
      gB01_1.CodCobrador := DR.CodCobrador;
      P_LOG('Ruta de cobro '||gB01_1.CodRuta||' - '||DR.DescRuta||' cobrador '||DR.CodCobrador);
    ELSE
      P_AVISO('Ruta de cobro '||NVL(gB01_1.CodRuta,'(vacia)')||' INVALIDO');
    END IF;
    gB01_1TipFin := gC00_12.cTipoFinanc; -- :B01_1.cTipoFin := :C00.cTipoFinanc
    IF gB01_1TipFin = 'CCA' THEN 
     gB01_1.CodFormCobro := 'CCA'; -- Cargo en Cuenta
    ELSE 
     gB01_1.CodFormCobro := 'COB'; -- Cobrador
    END IF;
    -- :B01_1.CodPlanFracc ya tiene valor (lo creo FR_Generar_Resp_Pago): no se busca plan por defecto
    IF gB01_1.CodPlanFracc IS NULL THEN
      BEGIN
        SELECT CodPlan, ModPlan, NroGiros 
    INTO gB01_1.CodPlanFracc, gB01_1.NumModPlanFracc, gB01_1.CantCuo
        FROM ACSELX.PLAN_FINANCIAMIENTO 
    WHERE TipoFin = gB01_1TipFin 
    AND TipoCli = C.TipoCli;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN 
       P_AVISO('No existe plan de financiamiento para Tipo Financiamiento '||gB01_1TipFin);
        WHEN TOO_MANY_ROWS THEN 
       gB01_1.CodPlanFracc := NULL;
      END;

      IF gC00_12.cTipoFinanc IN ('CON','LET') THEN 
       gB01_1.TipoModCob := 'EFE';
      ELSIF gC00_12.cTipoFinanc = 'CCA' THEN 
       gB01_1.TipoModCob := 'CCA';
      ELSIF gC00_12.cTipoFinanc = 'CUP' THEN 
       gB01_1.TipoModCob := 'EFE';
      END IF;

    END IF;
    -- Documento de pago del cliente (CSEF-8036: si no hay por defecto, toma el no defecto)
    IF gB01_1.CodFormCobro IS NULL OR gB01_1.CodFormCobro != 'DCA' THEN
      BEGIN
        SELECT NumDocRef, NumDoc INTO gB01_1.NumDocRef, gB01_1.NumDoc
        FROM   ACSELX.DOC_PAGO_CLIENTE WHERE CodCli = gB01_1.CodCli AND IndDocDef = 'S';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT NumDocRef, NumDoc INTO gB01_1.NumDocRef, gB01_1.NumDoc
            FROM   ACSELX.DOC_PAGO_CLIENTE WHERE CodCli = gB01_1.CodCli AND IndDocDef = 'N';
          EXCEPTION WHEN OTHERS THEN gB01_1.NumDocRef := NULL; gB01_1.NumDoc := NULL;
          END;
        WHEN OTHERS THEN gB01_1.NumDocRef := NULL; gB01_1.NumDoc := NULL;
      END;
    END IF;

    IF gB01_1.NumDoc IS NOT NULL THEN
      D  := ACSELX.PR_Cond_Financiamiento2.Datos_Doc_Pago_Cliente(gB01_1.CodCli, gB01_1.NumDoc);
      TJ := ACSELX.PR_Cond_Financiamiento2.Datos_Tarj_Cred(D.CodEntFinan, D.CodTarjCred);
      gB01_1.CodCobrador := TJ.CodCobrador;
      E  := ACSELX.PR_Tercero.Datos_Ent_Finan(D.CodEntFinan);
      IF E.DesCentFinan IS NULL THEN P_AVISO('Entidad Financiera Inexistente'); END IF;
    END IF;
    FIN_PASO('Nuevo responsable '||gB01_1.CodCli||' - '||ACSELX.PR_Imprime_Poliza.Nombre_Persona('N',T.NumId)||
             ' (TipoCli '||C.TipoCli||') FormCobro '||gB01_1.CodFormCobro||' Ruta '||gB01_1.CodRuta||
             ' DocPago '||NVL(TO_CHAR(gB01_1.NumDoc),'-'));
  END F12_CAMBIAR_RESPONSABLE;

  -- ================================================================================================
  -- 09. Cambio de plan en :B01_1.CodPlanFracc  (regla de negocio: moneda + persona juridica/natural)
  -- ================================================================================================
  PROCEDURE F12_CAMBIAR_PLAN IS
    --cPersona  VARCHAR2(10);
    cPlan     ACSELX.PLAN_FINANCIAMIENTO.CodPlan%TYPE;
    cNomPlan  ACSELX.PLAN_FINANCIAMIENTO.NomPlan%TYPE;
  BEGIN
    INICIO_PASO('09.CAMBIO PLAN','FIN00012 | B01_1.CODPLANFRACC | PRE-TEXT-ITEM / WHEN-VALIDATE-ITEM / POST-TEXT-ITEM');
    P_LOG('gCliAseg.TipoCli '||gCliAseg.TipoCli||' ,  gC00_12.cCodMonedaAnt '||gC00_12.cCodMonedaAnt);
    -- Regla de negocio
    
    IF gCliAseg.TipoCli IN('P') THEN

       IF gC00_12.cCodMonedaAnt = 'SOL' THEN
           cPlan := kPlanSolNat;
       END IF;
       
       IF gC00_12.cCodMonedaAnt = 'DOL' THEN
           cPlan := kPlanUsdNat;
       END IF;
       
    ELSE
       P_ERROR('El cliente  '||gB01_1.CodCli||'/'||gCliAseg.TipoCli||' '|| 'no tiene configurado el plan.');
    END IF
    
    IF cPlan IS NULL THEN
      P_ERROR('No hay regla de plan para la moneda '||gC00_12.cCodMonedaAnt||' (solo SOL y USD)');
    END IF;
    
    P_LOG('Regla: moneda '||gC00_12.cCodMonedaAnt||' + persona '||cPersona||' (TipoCli '||gCliAseg.TipoCli||
          ') => plan '||cPlan);

    -- PRE-TEXT-ITEM
    gC00_12.cCodPlanFracc := gB01_1.CodPlanFracc;
    gB01_1.CodPlanFracc   := cPlan;

    -- WHEN-VALIDATE-ITEM
    BEGIN
      SELECT ModPlan, NomPlan, TipoFin, NroGiros
      INTO   gB01_1.NumModPlanFracc, cNomPlan, gB01_1TipFin, gB01_1.CantCuo
      FROM   ACSELX.PLAN_FINANCIAMIENTO
      WHERE  CodPlan = gB01_1.CodPlanFracc;/*
      AND  StsPlan = 'ACT'
      AND  ModPlan = (SELECT MAX(P2.ModPlan) 
                    FROM ACSELX.PLAN_FINANCIAMIENTO P2
                        WHERE P2.CodPlan = gB01_1.CodPlanFracc 
            AND P2.StsPlan = 'ACT');*/
    EXCEPTION
      WHEN OTHERS THEN 
       P_ERROR('No existe el plan de financiamiento ACT '||gB01_1.CodPlanFracc||' (LOV)');
    END;
    IF gB01_1TipFin = 'CCA' THEN
      gB01_1.TipoModCob := 'CCA';
    ELSIF gB01_1TipFin IN ('CON','LET') THEN
      gB01_1.TipoModCob := 'EFE';
    ELSIF gB01_1TipFin = 'CUP' THEN
      gB01_1.TipoModCob := 'EFE';
    END IF;

    -- POST-TEXT-ITEM
    IF gC00_12.cCodPlanFracc != gB01_1.CodPlanFracc AND gC00_12.cCodPlanFracc IS NOT NULL THEN

      DELETE ACSELX.FINANC_DOC_PAGO_CLIENTE_T
      WHERE  IdTipo  = gB01_1.NumRefinanc
      AND  CodCli  = gB01_1.CodCli
      AND  NumDoc  = gB01_1.NumDoc
      AND  IndTipo = 'R'
      AND  NumCert = 0;

    gB01_1.CodFormCobro := NULL;
      gB01_1.NumDocRef := NULL;
      gB01_1.NumDoc := NULL;
    
      P_LOG('Plan cambiado de '||gC00_12.cCodPlanFracc||' a '||gB01_1.CodPlanFracc||
            ': se limpia forma de cobro y documento de pago (POST-TEXT-ITEM)');

    END IF;

    FIN_PASO('Plan '||gB01_1.CodPlanFracc||'-'||gB01_1.NumModPlanFracc||' '||cNomPlan||' TipoFin '||gB01_1TipFin||
             ' Cuotas '||gB01_1.CantCuo||' ModCob '||gB01_1.TipoModCob);
  END F12_CAMBIAR_PLAN;

  -- ================================================================================================
  -- 10a. FR_Commit_Form del bloque B01_1 (UPDATE de ACSELX.RESP_PAGO_REFRA)
  -- ================================================================================================
  PROCEDURE F12_GRABAR_B01_1 IS
  BEGIN
    P_LOG('FR_Commit_Form de B01_1 (PRE-UPDATE P17 + UPDATE ACSELX.RESP_PAGO_REFRA)');
    gB01_1.DiaCobro := 1;
    gB01_1.FormFact := 'PRP';
    IF gB01_1.CodFormCobro IN ('DBA','TCR') THEN
      IF gB01_1.NumDoc IS NULL THEN P_ERROR('Debe indicar un documento de pago'); END IF;
    END IF;

    UPDATE ACSELX.RESP_PAGO_REFRA
    SET    CodCli          = gB01_1.CodCli,
           PorcPago        = gB01_1.PorcPago,
           CodPlanFracc    = gB01_1.CodPlanFracc,
           NumModPlanFracc = gB01_1.NumModPlanFracc,
           CantCuo         = gB01_1.CantCuo,
           CodPais         = gB01_1.CodPais,
           CodEstado       = gB01_1.CodEstado,
           CodCiudad       = gB01_1.CodCiudad,
           CodMunicipio    = gB01_1.CodMunicipio,
           Direc           = gB01_1.Direc,
           Telef1          = gB01_1.Telef1,
           Telef2          = gB01_1.Telef2,
           Telef3          = gB01_1.Telef3,
           Fax             = gB01_1.Fax,
           Telex           = gB01_1.Telex,
           Zip             = gB01_1.Zip,
           CodZonaPostal   = gB01_1.CodZonaPostal,
           CodRuta         = gB01_1.CodRuta,
           CodCobrador     = gB01_1.CodCobrador,
           CodFormCobro    = gB01_1.CodFormCobro,
           NumDocRef       = gB01_1.NumDocRef,
           NumDoc          = gB01_1.NumDoc,
           TipoModCob      = gB01_1.TipoModCob,
           DiaCobro        = gB01_1.DiaCobro,
           FormFact        = gB01_1.FormFact
    WHERE  NumRefinanc = gC00_12.nNumRefinanc
      AND  CodCli      = gB01_1Ant;

    IF SQL%ROWCOUNT <> 1 THEN
      P_ERROR('No se pudo actualizar RESP_PAGO_REFRA (NumRefinanc '||gC00_12.nNumRefinanc||', CodCli '||gB01_1Ant||')');
    END IF;
    gB01_1Ant := gB01_1.CodCli;
  END F12_GRABAR_B01_1;

  -- ================================================================================================
  -- 10b. [FIN00012 | unidad FR_Fraccionar]  propuesta de refinanciamiento
  -- ================================================================================================
  PROCEDURE F12_FR_FRACCIONAR IS
    U         ACSELX.USUARIO%ROWTYPE;
    P         ACSELX.PLAN_FINANCIAMIENTO%ROWTYPE;
    cCodSuc   VARCHAR2(20);
    cMensaje  VARCHAR2(2000);
    rops      ACSELX.OPER_POL_STATUS%ROWTYPE;
    cStatusP  ACSELX.OPER_POL_STATUS.Status%TYPE;
    nIdepol   ACSELX.OPER_POL_STATUS.Idepol%TYPE;
  BEGIN
    P_LOG('Unidad FR_Fraccionar: Generando Propuesta de Re-Financiamiento inicial...');
    BEGIN
      ACSELX.PR_Cond_Financiamiento2.Iniciar_Fraccionamiento(gC00_12.nNumOper, gC00_12.dFecEmi);
      -- N3039924
      BEGIN
        SELECT MAX(IdePol) 
    INTO nIdePol 
    FROM ACSELX.OPER_POL 
    WHERE NumOper = gC00_12.nNumOper;

        SELECT DISTINCT OPS.Status 
    INTO cStatusP
        FROM   ACSELX.OPER_POL_STATUS OPS
        WHERE  OPS.IdePol  = nIdePol
        AND  OPS.NumOper = (SELECT MAX(OPS2.NumOper)
                            FROM ACSELX.OPER_POL_STATUS OPS2, ACSELX.OPER_POL OP
                            WHERE OPS2.IdePol = nIdePol 
              AND NVL(OP.IndAnul,'N') = 'N'
                            AND OPS2.IdePol = OP.IdePol 
              AND OPS2.NumOper = OP.NumOper);

      EXCEPTION 
       WHEN NO_DATA_FOUND THEN 
       cStatusP := 0;
      END;

      rops.IdePol  := nIdePol;
      rops.NumOper := gC00_12.nNumOper;
      rops.Status  := cStatusP;
      rops.CodUsr  := ACSELX.PR_SESION.USUARIO_APP;
      rops.Fecha   := SYSDATE;
      ACSELX.PR_POLIZA_MASIVA.Crear_Oper_Pol_St(rops);
    EXCEPTION
      WHEN OTHERS THEN 
      P_ERROR('Error al fraccionar: '||SQLERRM);
    END;

    BEGIN
      ACSELX.PR_Cond_Financiamiento2.Obtener_Vigencia_Financ(gC00_12.nNumOper, gC00_12.nNumRefinanc,
                                                             gC00_12.dFecIniVig, gC00_12.dFecFinVig);
    EXCEPTION
      WHEN OTHERS THEN 
     P_ERROR('Error al fraccionar: '||SQLERRM);
    END;

    P_LOG('Vigencia: '||TO_CHAR(gC00_12.dFecIniVig,'dd/mm/yyyy')||' - '||TO_CHAR(gC00_12.dFecFinVig,'dd/mm/yyyy'));
    
  U := ACSELX.PR_Usuario.Datos_Usuario(USER);

  IF U.NomUsr IS NOT NULL THEN 
     cCodSuc := U.CodSuc; 
  ELSE 
     cCodSuc := '010000'; 
  END IF;

  BEGIN
      ACSELX.PR_Cond_Financiamiento.Refraccionar(gC00_12.nNumRefinanc, gC00_12.nTotMtoOper, gC00_12.nTotComiOper,
                                                 gC00_12.cCodMonedaAnt, cCodSuc, gC00_12.dFecIniVig,
                                                 gC00_12.dFecFinVig, gC00_12.nNumOper, gC00_12.dFecEmi);
    EXCEPTION
      WHEN OTHERS THEN 
      P_ERROR('Error al fraccionar: '||SQLERRM);
    END;
    -- Politica 007: numero de cuotas (N3020285)
    P := ACSELX.PR_COND_FINANCIAMIENTO2.DATOS_PLAN_FINANC(gB01_1.CodPlanFracc, gB01_1.NumModPlanFracc);
    IF gB01_1.CantCuo > NVL(P.NroGiros,0) THEN
      cMensaje := cMensaje||'Se cambio Cant. Cuotas de '||TO_CHAR(P.NroGiros)||' a '||TO_CHAR(gB01_1.CantCuo)||CHR(10);
      ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '007', cMensaje);
    END IF;
  END F12_FR_FRACCIONAR;

  -- ================================================================================================
  -- 10c. Consulta de B03_1 en FIN00012 (FR_Refrescar_Bloque('B03_1'))
  -- ================================================================================================
  PROCEDURE F12_CONSULTAR_B03_1 IS
  BEGIN

    SELECT * 
  INTO gCF12 
  FROM ACSELX.COND_FINANCIAMIENTO
  WHERE  NumRefinanc = gC00_12.nNumRefinanc;

    gFec1erVenc := ACSELX.PR_Cond_Financiamiento2.Fecha_Vcto_Giro_Financ(gCF12.NumFinanc,'PRI');
    gC01.cTipoFinAux       := gCF12.TipoFin;
    gC01.cIndIntInicialAux := gCF12.IndIntInicial;
    gC01.nFrecuenciaAux    := gCF12.Frecuencia;
    gC01.nPorcInicialAux   := gCF12.PorcInicial;
    gC01.nPorcInteresAux   := gCF12.PorcInteres;
    gC01.nCantGirosAux     := gCF12.CantGiros;
    gC01.dFec1erVencAux    := gFec1erVenc;
    gC01.nMtoGastosAux     := gCF12.MtoGastos;

    P_LOG('B03_1: financ nuevo '||gCF12.NumFinanc||' TipoFin '||gCF12.TipoFin||' Plan '||gCF12.CodPlan||'-'||
          gCF12.ModPlan||' Cuotas '||gCF12.CantGiros||' 1er venc '||TO_CHAR(gFec1erVenc,'dd/mm/yyyy')||
          ' Total '||gCF12.MtoPago||' Gastos '||gCF12.MtoGastos);

  END F12_CONSULTAR_B03_1;

  -- ================================================================================================
  -- 10. [FIN00012 | B01_1 | KEY-NXTBLK | P21]  pasar al bloque siguiente = generar la propuesta
  -- ================================================================================================
  PROCEDURE F12_SIGUIENTE_BLOQUE IS
    nPorcPago  ACSELX.RESP_PAGO.PorcPago%TYPE;
    cExiste    VARCHAR2(1);
  BEGIN
    INICIO_PASO('10.KEY-NXTBLK B01_1','FIN00012 | B01_1 | KEY-NXTBLK | P21');
    -- N3036890
    IF gB01_1.TipoModCob IN ('DPP','CCA') THEN
      IF gB01_1.TipoModCob = 'DPP' THEN
        IF gB01_1.NumAutoriza IS NULL THEN 
       P_ERROR('Ingrese el Numero de Pago Facil.'); 
    END IF;
      ELSE
        IF gB01_1.NumDocRef IS NULL THEN
          P_ERROR('Ingrese el Numero de Cuenta Bancaria o Numero de Tarjeta de Credito.');
        END IF;
      END IF;
    END IF;
    IF gB01_1.CodCli IS NOT NULL AND gB01_1.CodPlanFracc IS NOT NULL THEN
      IF gC00_12.cIndCrear = kSi THEN
        IF gC00_12.cTipoFinanc = 'CCA' THEN
          IF gB01_1.NumDocRef IS NULL THEN
            P_ERROR('Debe ingresar la autorizacion de Cargo en Cuenta');
          ELSE
            cExiste := ACSELX.PR_Cond_Financiamiento2.Valida_Financ_Doc_Pago_Cli_T(gB01_1.NumRefinanc, gB01_1.CodCli,
                                                                                   gB01_1.NumDoc, 'R', 0);
            IF cExiste = kNo THEN 
         P_ERROR('Debe ingresar la autorizacion de Cargo en Cuenta'); 
      END IF;
          END IF;
        END IF;
    
        F12_GRABAR_B01_1;  -- FR_Commit_Form
        
    SELECT NVL(SUM(PorcPago),0) 
    INTO nPorcPago
        FROM ACSELX.RESP_PAGO_REFRA 
    WHERE NumRefinanc = gB01_1.NumRefinanc;

        IF nPorcPago <> 100 THEN
          P_ERROR('La suma de Porcentajes de los Responsables de Pago deben ser 100%');
        END IF;

        F12_FR_FRACCIONAR;

        IF gC00_12.cIndPolTransc = kSi AND gC00_12.nNumOperMacsi IS NOT NULL THEN
          P_ERROR('Poliza transcrita: continua en MIGREFMACSI (no soportado)');
        END IF;
    
        F12_CONSULTAR_B03_1;  -- FR_Refrescar_Bloque('B03_1')
      END IF;
    ELSE
      P_ERROR('Falta el responsable o el plan en B01_1');
    END IF;
    FIN_PASO('Propuesta generada');
  END F12_SIGUIENTE_BLOQUE;

  -- ================================================================================================
  -- 11a. [FIN00012 | unidad FR_Verificar_Politicas_Vio(cIndPrefijada)]
  -- ================================================================================================
  PROCEDURE F12_FR_VERIFICAR_POLITICAS_VIO(p_cIndPrefijada VARCHAR2) IS
    P               ACSELX.PLAN_FINANCIAMIENTO%ROWTYPE;
    nTasaCambio     NUMBER;
    nTasaCambioMin  NUMBER;
    cDescPolVio     VARCHAR2(32767);
    cMensaje        VARCHAR2(2000);
    cMensPrefijada  VARCHAR2(2000);
    cCaracter       VARCHAR2(1);
    cIndModTexto    VARCHAR2(1);
    PROCEDURE Eliminar_Politica(p_cCodPolVio VARCHAR2) IS
    BEGIN
      DELETE ACSELX.POLITICA_VIOLADA_REFRA 
    WHERE NumRefinanc = gC00_12.nNumRefinanc 
    AND CodPolVio = p_cCodPolVio;
    END Eliminar_Politica;
    
  PROCEDURE Modificar_Politica(p_cCodPolVio VARCHAR2, p_cTextPolVio VARCHAR2) IS
      cTextPolVio VARCHAR2(32767);
    BEGIN
      IF p_cCodPolVio IS NOT NULL THEN 
       Eliminar_Politica(p_cCodPolVio);
    END IF;
      
    cTextPolVio := ACSELX.PR_Cond_Financiamiento2.Desc_Politica_Violada(gC00_12.nNumRefinanc);
      
    IF cTextPolVio IS NOT NULL THEN
        UPDATE ACSELX.TEXTO_POLITICA_VIOLADA
        SET    DescPolVio = SUBSTR(cTextPolVio,1,INSTR(cTextPolVio,p_cTextPolVio,1)-1)||
                            SUBSTR(cTextPolVio,INSTR(cTextPolVio,CHR(10),INSTR(cTextPolVio,p_cTextPolVio,1))+1)
        WHERE  NumRefinanc = gC00_12.nNumRefinanc;
      END IF;
    END Modificar_Politica;
  BEGIN
    P_LOG('Unidad FR_Verificar_Politicas_Vio('||p_cIndPrefijada||')');
    P := ACSELX.PR_Cond_Financiamiento2.Datos_Plan_Financ(gCF12.CodPlan, gCF12.ModPlan);
    cDescPolVio := ACSELX.PR_Cond_Financiamiento2.Desc_Politica_Violada(gC00_12.nNumRefinanc);
    IF cDescPolVio IS NOT NULL THEN
      UPDATE ACSELX.TEXTO_POLITICA_VIOLADA
      SET    DescPolVio = SUBSTR(cDescPolVio,1,INSTR(cDescPolVio,'No puede haber Mas de',1)-1)||
                          SUBSTR(cDescPolVio,INSTR(cDescPolVio,'Pago')+4)
      WHERE  NumRefinanc = gC00_12.nNumRefinanc;
    END IF;

    DELETE ACSELX.POLITICA_VIOLADA_REFRA 
  WHERE NumRefinanc = gC00_12.nNumRefinanc 
  AND CodPolVio IN ('001','002');

  cDescPolVio := ACSELX.PR_Cond_Financiamiento2.Desc_Politica_Violada(gC00_12.nNumRefinanc);
    
  LOOP
      cCaracter := SUBSTR(cDescPolVio, LENGTH(cDescPolVio));
      EXIT WHEN NVL(cCaracter,'X') <> CHR(10);
      cDescPolVio  := SUBSTR(cDescPolVio, 1, LENGTH(cDescPolVio)-1);
      cIndModTexto := '1';
    END LOOP;

    IF cIndModTexto IS NOT NULL THEN
      UPDATE ACSELX.TEXTO_POLITICA_VIOLADA 
    SET DescPolVio = cDescPolVio 
    WHERE NumRefinanc = gC00_12.nNumRefinanc;
    END IF;

    IF gCF12.Frecuencia != gC01.nFrecuenciaAux AND gCF12.Frecuencia != NVL(P.Frecuencia,0) THEN
      IF (gCF12.Frecuencia * gCF12.CantGiros) > P.CantMeses THEN
        Modificar_Politica('004','Se cambio Frecuencia de');
        cMensaje := cMensaje||'Se cambio Frecuencia de '||TO_CHAR(gC01.nFrecuenciaAux)||' a '||TO_CHAR(gCF12.Frecuencia)||CHR(10);
        ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '004', cMensaje);
      END IF;
    END IF;

    IF gCF12.PorcInicial != gC01.nPorcInicialAux AND gCF12.PorcInicial < NVL(P.PorIniMin,0) THEN
      Modificar_Politica('005','Se cambio Porc. Inicial de');
      cMensaje := cMensaje||'Se cambio Porc. Inicial de '||TO_CHAR(gC01.nPorcInicialAux,'990.0000')||
                  ' a '||TO_CHAR(gCF12.PorcInicial,'990.0000')||CHR(10);
      ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '005', cMensaje);
    END IF;

    IF gCF12.PorcInteres != gC01.nPorcInteresAux AND gCF12.PorcInteres < NVL(P.PorcInteres,0) THEN
      Modificar_Politica('006','Se cambio Porc. Interes de');
      cMensaje := cMensaje||'Se cambio Porc. Interes de '||TO_CHAR(gC01.nPorcInteresAux,'990.0000')||
                  ' a '||TO_CHAR(gCF12.PorcInteres,'990.0000')||CHR(10);
      ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '006', cMensaje);
    END IF;

    IF gCF12.CantGiros != gC01.nCantGirosAux AND gCF12.CantGiros > NVL(P.NroGiros,0) THEN
      Modificar_Politica('007','Se cambio Cant. Cuotas de');
      cMensaje := cMensaje||'Se cambio Cant. Cuotas de '||TO_CHAR(gC01.nCantGirosAux)||' a '||TO_CHAR(gCF12.CantGiros)||CHR(10);
      ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '007', cMensaje);
    END IF;

    IF gCF12.MtoGastos != gC01.nMtoGastosAux THEN
      Modificar_Politica('010','Se cambio Derecho de Emision de');
      cMensaje := cMensaje||'Se cambio Derecho de Emision de '||TO_CHAR(gC01.nMtoGastosAux)||' a '||TO_CHAR(gCF12.MtoGastos)||CHR(10);
      ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '010', cMensaje);
    END IF;

    IF p_cIndPrefijada = 'R' THEN
      Eliminar_Politica('008');
      nTasaCambio    := ACSELX.PR.TASA_CAMBIO(gCF12.CodMoneda, P.CodMoneda, gCF12.FecCar, 'D');
      nTasaCambioMin := ACSELX.PR.TASA_CAMBIO(P.CodMoneda, gCF12.CodMoneda, gCF12.FecCar, 'D');
      FOR g IN (SELECT NumGiro, MtoGiroForaneo, IndCambio -- bloque B03_2 (GIROS_FINANCIAMIENTO_T)
                FROM   ACSELX.GIROS_FINANCIAMIENTO_T 
        WHERE NumFinanc = gCF12.NumFinanc 
        ORDER BY NumGiro) LOOP
        IF g.IndCambio = kSi THEN
          IF (g.MtoGiroForaneo * nTasaCambio) < P.MtoMinimo THEN
            Modificar_Politica(NULL,'Cuota prefijada');
            cMensPrefijada := 'Cuota prefijada '||TO_CHAR(g.NumGiro)||' es menor a monto minimo ('||
                              LTRIM(TO_CHAR(P.MtoMinimo*nTasaCambioMin,'999,990.00'))||')'||CHR(10);
            cMensaje := cMensaje||cMensPrefijada;
          END IF;
        END IF;
      END LOOP;
      IF cMensPrefijada IS NOT NULL THEN
        ACSELX.PR_COND_FINANCIAMIENTO.CREAR_POLITICA_VIOLADA(gC00_12.nNumRefinanc, '008', cMensaje);
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN 
    P_ERROR('Error en politicas violadas: '||SQLERRM);
  END F12_FR_VERIFICAR_POLITICAS_VIO;

  -- ================================================================================================
  -- 11. [FIN00012 | C03.RECALCULAR | WHEN-BUTTON-PRESSED | P88] -> unidad FR_RECALCULAR
  -- ================================================================================================
  PROCEDURE F12_FR_RECALCULAR IS
    nTasaCambio      NUMBER;
    nMtoComi         ACSELX.GIROS_FINANCIAMIENTO.MtoComGiro%TYPE;
    nMtoMinimo       NUMBER(14,2);
    nMtoGtoEmi       NUMBER(14,2);
    nCantDiasMin     NUMBER(3);
    cCodMonedaPlan   VARCHAR2(3);
    cCodMonedaLocal  VARCHAR2(3);
    cCodMoneda       VARCHAR2(3);
    cIndCalculo      VARCHAR2(1);
    cIndOk           VARCHAR2(1) := kNo;
    nMtoPago         NUMBER(14,2);
    P                ACSELX.PLAN_FINANCIAMIENTO%ROWTYPE;
  BEGIN
    INICIO_PASO('11.RECALCULAR','FIN00012 | C03.RECALCULAR | WHEN-BUTTON-PRESSED| FR_RECALCULAR');
    cCodMoneda := gCF12.CodMoneda;

    -- ACTUALIZAR_TIPO_REDONDEO (N3020398)
    UPDATE ACSELX.RESP_PAGO_REFRA 
  SET TipoRed = gCF12.TipoRed
    WHERE  NumRefinanc = gB01_1.NumRefinanc 
  AND CodCli = gB01_1.CodCli;

  UPDATE ACSELX.COND_FINANCIAMIENTO 
  SET TipoRed = gCF12.TipoRed 
  WHERE NumFinanc = gCF12.NumFinanc;

    -- 'C' si se cambio algun dato de B03_1 respecto a C01; 'R' si no
    IF gCF12.TipoFin != gC01.cTipoFinAux OR gCF12.IndIntInicial != gC01.cIndIntInicialAux OR
       gCF12.Frecuencia != gC01.nFrecuenciaAux OR gCF12.PorcInicial != gC01.nPorcInicialAux OR
       gCF12.PorcInteres != gC01.nPorcInteresAux OR gCF12.CantGiros != gC01.nCantGirosAux OR
       gFec1erVenc != gC01.dFec1erVencAux OR gCF12.MtoGastos != gC01.nMtoGastosAux THEN
      cIndCalculo := 'C';
    ELSE
      cIndCalculo := 'R';
    END IF;

    P_LOG('cIndCalculo = '||cIndCalculo);

    IF cIndCalculo = 'R' THEN                               -- recorre B03_2 buscando una cuota no prefijada
      FOR g IN (SELECT IndCambio FROM ACSELX.GIROS_FINANCIAMIENTO_T WHERE NumFinanc = gCF12.NumFinanc) LOOP
        IF g.IndCambio = kNo THEN cIndOk := kSi; EXIT; END IF;
      END LOOP;
      IF cIndOk = kNo THEN P_ERROR('No puede Prefijar todas las Cuotas. Al menos una debe ser Calculada.'); END IF;
    END IF;

    F12_FR_VERIFICAR_POLITICAS_VIO(cIndCalculo);
    P := ACSELX.PR_Cond_Financiamiento2.Datos_Plan_Financ(gCF12.CodPlan, gCF12.ModPlan);
    nMtoMinimo     := P.MtoMinimo;
    nCantDiasMin   := P.CantDiasMin;
    cCodMonedaPlan := P.CodMoneda;

    IF cCodMoneda != cCodMonedaPlan THEN
      nMtoMinimo := nMtoMinimo * ACSELX.PR.Tasa_Cambio(cCodMonedaPlan, cCodMoneda, gCF12.FecCar, 'D');
    END IF;

    SELECT SUM(NVL(MtoComGiro,0)) 
  INTO nMtoComi 
  FROM ACSELX.GIROS_FINANCIAMIENTO 
  WHERE NumFinanc = gCF12.NumFinanc;

    ACSELX.PR_Vinisusc.Cargar;
    cCodMonedaLocal := ACSELX.PR_Vinisusc.Codigo_Moneda;
    nTasaCambio := ACSELX.PR.Tasa_Cambio(cCodMoneda, cCodMonedaLocal, SYSDATE, 'D');

    BEGIN
      SELECT (gCF12.MtoNetoFrac * ACSELX.PR.Busca_Impues_Conc_Finan(gCF12.CodPlan, gCF12.ModPlan, 'GRUFIN', 'GTOEMI', SYSDATE)) / 100
      INTO   nMtoGtoEmi
      FROM   ACSELX.CONC_FINANCIAMIENTO
      WHERE  CodPlan = gCF12.CodPlan AND ModPlan = gCF12.ModPlan
        AND  CodGrupoAcre = 'GRUFIN' AND CodCptoAcre = 'GTOEMI';
    EXCEPTION 
   WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN 
      nMtoGtoEmi := 0;
    END;
    
  IF gCF12.MtoGastos != gC01.nMtoGastosAux THEN
      nMtoGtoEmi := gCF12.MtoGastos;
    ELSE
      IF gCF12.MtoGastos = nMtoGtoEmi THEN nMtoGtoEmi := -1; ELSE nMtoGtoEmi := gCF12.MtoGastos; END IF;
    END IF;
    
  P_LOG('Calcula_Finan(NumFinanc '||gCF12.NumFinanc||', neto '||gCF12.MtoNetoFrac||', comision '||nMtoComi||
          ', plan '||gCF12.CodPlan||'-'||gCF12.ModPlan||', cuotas '||gCF12.CantGiros||', 1er venc '||
          TO_CHAR(gFec1erVenc,'dd/mm/yyyy')||', '||cIndCalculo||')');
    
  ACSELX.PR_Cond_Financiamiento.Calcula_Finan(gCF12.NumFinanc, gCF12.MtoNetoFrac, nMtoComi, gCF12.CodPlan, gCF12.CantGiros,
                                                gCF12.PorcInicial, gCF12.PorcInteres, gCF12.Frecuencia, gCF12.ModPlan,
                                                gC00_12.dFecIniVig, gFec1erVenc, nTasaCambio, nMtoMinimo, nCantDiasMin,
                                                gC00_12.dFecFinVig, gCF12.TipoFin, cIndCalculo, nMtoGtoEmi, NULL, NULL, 'N');
    nMtoPago := ACSELX.PR_Cond_Financiamiento2.Monto_Total_Giro_Foraneo(gCF12.NumFinanc);
    
  UPDATE ACSELX.COND_FINANCIAMIENTO
    SET MtoPago = ROUND(nMtoPago,2), 
      MtoPagoLocal = ROUND(nMtoPago,2) * nTasaCambio
    WHERE  NumFinanc = gCF12.NumFinanc;
  
    SELECT SUM(NVL(MtoDetGiroMoneda,0)) 
  INTO nMtoGtoEmi
    FROM ACSELX.DET_GIRO_FIN 
  WHERE NumFinanc = gCF12.NumFinanc 
  AND CodCptoAcre = 'GTOEMI';
    
  UPDATE ACSELX.COND_FINANCIAMIENTO
    SET MtoGastos = ROUND(nMtoGtoEmi,2), 
      MtoGastosLocal = ROUND(nMtoGtoEmi,2) * nTasaCambio
    WHERE  NumFinanc = gCF12.NumFinanc;
    
  F12_CONSULTAR_B03_1;  -- FR_Refrescar_Bloque('B03_1')
    
  FOR g IN (SELECT NumGiro, FecVct, MtoGiroForaneo 
            FROM ACSELX.GIROS_FINANCIAMIENTO
              WHERE NumFinanc = gCF12.NumFinanc 
        ORDER BY NumGiro) LOOP
      P_LOG('   Cuota '||LPAD(g.NumGiro,3)||'  vence '||TO_CHAR(g.FecVct,'dd/mm/yyyy')||'  monto '||
            LPAD(TO_CHAR(g.MtoGiroForaneo,'FM999,999,990.00'),14));
    END LOOP;
  
    FIN_PASO('Total '||gCF12.MtoPago||' '||gCF12.CodMoneda||' en '||gCF12.CantGiros||' cuotas, gastos emision '||gCF12.MtoGastos);
  END F12_FR_RECALCULAR;

  -- ================================================================================================
  -- 12. Motivo de refinanciamiento
  -- ================================================================================================
  PROCEDURE F12_MOTIVO IS
  BEGIN
    INICIO_PASO('12.MOTIVO','FIN00012 | C03.MOTIVO P91 / B04_1.CCODMOTVANUL P165 / B04_1 P166');
    BEGIN
      SELECT CodLval 
    INTO gB04_1.cCodMotvAnul
      FROM ACSELX.LVAL 
    WHERE TipoLval = 'MOTREFIN' 
    AND CODLVAL = p_cMotRefi;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN 
       P_ERROR('No existe el motivo '||kMotivoDesc||' en LVAL MOTREFIN');
    END;
    gB04_1.cDescMotvAnul := ACSELX.PR.Busca_Lval('MOTREFIN', gB04_1.cCodMotvAnul);
    IF gB04_1.cDescMotvAnul = 'INVALIDO' THEN
      P_ERROR('Codigo de motivo '||gB04_1.cCodMotvAnul||' INVALIDO');
    END IF;
    gB04_1.cTextMotvAnul := p_cObservacion;
    IF gB04_1.cCodMotvAnul IS NULL OR gB04_1.cDescMotvAnul IS NULL THEN
      P_ERROR('Debe ingresar el Motivo de Refinanciamiento. Por favor, revisar.');
    END IF;
    FIN_PASO('Motivo '||gB04_1.cCodMotvAnul||' - '||gB04_1.cDescMotvAnul||' | Observacion: '||gB04_1.cTextMotvAnul);
  END F12_MOTIVO;

  -- ================================================================================================
  -- 13a. [FIN00012 | unidad FR_Finalizar_Refra(p_nNumFinanc = NumRefinanc, p_nNumOper)]
  -- ================================================================================================
  PROCEDURE F12_FR_FINALIZAR_REFRA IS
    I             ACSELX.INTERMEDIARIO%ROWTYPE;
    cCodInter     ACSELX.PART_INTER_POL.CodInter%TYPE;
    cCodCobrador  ACSELX.INTERMEDIARIO.CodCobrador%TYPE;
    cNCompr       ACSELX.COMPROBANTE.NCompr%TYPE;
    cExiste       VARCHAR2(1);
  BEGIN
    P_LOG('Unidad FR_Finalizar_Refra: Generando Re-Financiamiento definitivo...');
    BEGIN
      SELECT PIP.CodInter 
    INTO cCodInter
      FROM   ACSELX.PART_INTER_POL PIP
      WHERE  PIP.IndLider = 'S'
        AND  EXISTS (SELECT 1 FROM ACSELX.OPER_POL 
                 WHERE NumOper = gC00_12.nNumOper 
           AND IdePol = PIP.IdePol)
      GROUP  BY PIP.CodInter;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN P_ERROR('No existe intermediario para las polizas de la operacion '||gC00_12.nNumOper);
      WHEN TOO_MANY_ROWS THEN P_ERROR('Existe mas de un intermediario para las polizas de la operacion '||gC00_12.nNumOper);
    END;

    I := ACSELX.PR_Intermediario.Datos_Inter(cCodInter);
    cCodCobrador := I.CodCobrador;
    P_LOG('Intermediario '||cCodInter||' cobrador '||cCodCobrador);

    P_LOG('Generando acreencias...');

    BEGIN
      ACSELX.PR_Cond_Financiamiento.Generar_Acreencia_Refra(gC00_12.nNumOper, cCodInter);
    EXCEPTION 
    WHEN OTHERS THEN 
      P_ERROR('Error al generar Acreencias '||SQLERRM);
    END;

    FOR C2 IN (SELECT CF.NumFinanc, RPR.CodCli, RPR.NumDoc -- N3028944 / N3036890
               FROM   ACSELX.COND_FINANCIAMIENTO CF, ACSELX.RESP_PAGO_REFRA RPR
               WHERE  CF.NumRefinanc = gC00_12.nNumRefinanc 
         AND RPR.NumRefinanc = CF.NumRefinanc
               AND (CF.TipoFin = 'CCA' OR RPR.TipoModCob = 'DPP')) LOOP
      BEGIN
        INSERT INTO ACSELX.FINANC_DOC_PAGO_CLIENTE (NumFinanc, CodCli, NumDoc, NumAutoriza)
        
    SELECT C2.NumFinanc, CodCli, NumDoc, NumAutoriza
        FROM   ACSELX.FINANC_DOC_PAGO_CLIENTE_T
        WHERE  IdTipo = gC00_12.nNumRefinanc 
    AND CodCli = C2.CodCli 
    AND NumDoc = C2.NumDoc
        AND  IndTipo = 'R' 
    AND NumCert = 0;
      EXCEPTION 
      WHEN OTHERS THEN 
      P_ERROR(' Error Insertando FINANC_DOC_PAGO_CLIENTE '||SQLERRM);
      END;
    END LOOP;

    P_LOG('Generando documentos de cobro...');
    BEGIN
      ACSELX.PR_Cond_Financiamiento.Generar_Factura_Refra(gC00_12.nNumOper, cCodInter, cCodCobrador);
    EXCEPTION WHEN OTHERS 
    THEN P_ERROR('Error al generar Facturas '||SQLERRM);
    END;

    FOR C3 IN (SELECT CF.NumFinanc, CF.NumRefinanc, CF.NumRefracc -- RTC 297027
               FROM   ACSELX.COND_FINANCIAMIENTO CF 
         WHERE CF.NumRefinanc = gC00_12.nNumRefinanc) LOOP
      BEGIN
        INSERT INTO ACSELX.COND_FINANC_REF (NumFinanc, NumRefinanc, NumRefracc, TipoRef, TextMotRef, CodUsr)
        VALUES (C3.NumFinanc, C3.NumRefinanc, C3.NumRefracc, gB04_1.cCodMotvAnul, gB04_1.cTextMotvAnul, USER);
      EXCEPTION WHEN OTHERS 
       THEN P_ERROR(' Error Insertando COND_FINANC_REF '||SQLERRM);
      END;

    END LOOP;

    P_LOG('Anulando financiamiento(s) anterior(es)...');
    FOR C1 IN (SELECT NumFinanc, NumRefracc, CodOfiEmi 
             FROM ACSELX.COND_FINANCIAMIENTO
               WHERE NumRefracc = gC00_12.nNumRefinanc) LOOP
      
    cNCompr := ACSELX.PR_Comprobante.Abrir_Comp;
      
    BEGIN
        ACSELX.PR_Operacion.Iniciar('REFIN','LIQ. LETRA',TO_CHAR(C1.NumFinanc));
        BEGIN                                              -- N3021194 (se evalua pero la forma no lo usa)
          SELECT kSi 
      INTO cExiste 
      FROM DUAL
          WHERE  EXISTS (SELECT 1 
                     FROM ACSELX.COND_FINANCIAMIENTO CF
                         WHERE CF.NumOper = gC00_12.nNumOper 
             AND CF.TipoFin = 'LET');
        EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
         cExiste := kNo;
        END;
        ACSELX.PR_Cond_Financiamiento.Anular(C1.NumFinanc, cNCompr);
        ACSELX.PR_Operacion.Terminar;
      EXCEPTION
        WHEN OTHERS THEN P_ERROR('Error al anular financiamiento original '||C1.NumFinanc||': '||SQLERRM);
      END;
      P_LOG('Anulado financ '||C1.NumFinanc||' comprobante '||cNCompr);
    END LOOP;

    -- :C00.cIndTranscripcion = 'S' (UPDATE OPER_POL_ACSEL_MACSI) no aplica: se rechazo en el paso 05
    P_LOG('Asignando Forma de Cobro...');
    BEGIN
      ACSELX.PR_Cond_Financiamiento2.Asignar_Forma_de_Cobro(gC00_12.nNumOper);
    EXCEPTION 
    WHEN OTHERS THEN 
      P_ERROR('Error Asignar Forma de Cobro '||SQLERRM);
    END;
  
    P_LOG('Generando facturas pendientes...');
    
  BEGIN
      ACSELX.PR_Cond_Financiamiento2.Generar_Facturas_Pendientes(gC00_12.nNumRefinanc, gC00_12.nNumOper);
    EXCEPTION WHEN OTHERS 
    THEN P_ERROR('Error Generar Facturas Pendientes '||SQLERRM);
    END;

    -- PR_DET_ACRE_REA_COA.Genera_Mov_Refina: COMENTADO en la forma (N3033126), Generar_Factura_Refra ya genera COA/REA
    P_LOG('Generando vigencias contables...');
    
  BEGIN
      ACSELX.PR_Cond_Financiamiento.Generar_Vigencia_Contable(gC00_12.nNumOper);
    EXCEPTION 
    WHEN OTHERS THEN 
     P_ERROR('Error Generar Vigencia Contable '||SQLERRM);
    END;

    P_LOG('Revirtiendo detalle de reaseguro y coaseguro de documentos originales...');
    
  BEGIN
      ACSELX.PR_DET_ACRE_REA_COA.REVERTIR_POLIZA_ANU(gC00_12.nNumOper, 'REM');
    EXCEPTION 
    WHEN OTHERS THEN 
      P_ERROR('Error Revirtiendo detalle de reaseguro y coaseguro '||SQLERRM);
    END;

  END F12_FR_FINALIZAR_REFRA;

  -- ================================================================================================
  -- 13. [FIN00012 | C03.ACEPTAR | WHEN-BUTTON-PRESSED]
  -- ================================================================================================
  PROCEDURE F12_ACEPTAR IS
    P                   ACSELX.PLAN_FINANCIAMIENTO%ROWTYPE;
    nPorcInteres        ACSELX.PLAN_FINANCIAMIENTO.PorcInteres%TYPE;
    nCantgiros          ACSELX.PLAN_FINANCIAMIENTO.NroGiros%TYPE;
    nPorcMinimo         NUMBER;
    nCantPolVio         NUMBER;
    nIndRefinanc        NUMBER;
    cDescPolVio         VARCHAR2(32767);
    Vc_Error            VARCHAR2(4000);
    nExiste             NUMBER;
    nExiSal             NUMBER;
    nFinancOK           NUMBER;
    nNumFinanc          ACSELX.COND_FINANCIAMIENTO.NumFinanc%TYPE;
    nValidaMtoMaxPrima  NUMBER;
    nMontoMaxPrima      NUMBER;
    nNumAutoriza        ACSELX.FINANC_DOC_PAGO_CLIENTE_T.NumAutoriza%TYPE;
  BEGIN
    INICIO_PASO('13.ACEPTAR','FIN00012 | C03.ACEPTAR | WHEN-BUTTON-PRESSED | P90');
    ACSELX.PR.Asigna_Rollback('FINANCIA');
    
  IF gCF12.TipoFin != gC01.cTipoFinAux OR gCF12.IndIntInicial != gC01.cIndIntInicialAux OR
       gCF12.Frecuencia != gC01.nFrecuenciaAux OR gCF12.PorcInicial != gC01.nPorcInicialAux OR
       gCF12.PorcInteres != gC01.nPorcInteresAux OR gCF12.CantGiros != gC01.nCantGirosAux OR
       gFec1erVenc != gC01.dFec1erVencAux OR gCF12.MtoGastos != gC01.nMtoGastosAux THEN
      P_ERROR('Existen cambios que deben ser recalculados. No puede aceptar el Re-Financiamiento');
    ELSIF gC00_12.cIndCrear = kSi AND gB04_1.cCodMotvAnul IS NULL AND gC00_12.nNumRefinanc IS NOT NULL THEN
      P_ERROR('Debe ingresar el Motivo de Refinanciamiento. Por favor, revisar.');
    END IF;

    P := ACSELX.PR_Cond_Financiamiento2.Datos_Plan_Financ(gCF12.CodPlan, gCF12.ModPlan);
    IF P.CodPlan IS NOT NULL THEN
      nPorcInteres := P.PorcInteres;
      nCantgiros   := P.NroGiros;
    ELSE
      P_ERROR('No existe plan de financiamiento con codigo '||gCF12.CodPlan||'-'||gCF12.ModPlan);
    END IF;
    -- RTC 310751: monto maximo de prima del plan con tarjeta de credito
    BEGIN
      SELECT 1 
    INTO nValidaMtoMaxPrima
      FROM   ACSELX.FINANC_DOC_PAGO_CLIENTE_T T, ACSELX.AUTORIZA_DOC_PAGO_CLIENTE C, ACSELX.DOC_PAGO_CLIENTE_ADI A
      WHERE  T.IdTipo = gC00_12.nNumRefinanc 
    AND T.IndTipo = 'R'
      AND  C.CodCli = T.CodCli 
    AND C.NumAutoriza = T.NumAutoriza
      AND C.CodCli = A.CodCli 
    AND A.TipoTarj = 'C' 
    AND C.NumDoc = A.NumDoc 
    AND C.StsDoc = 'ACT'
      AND  ROWNUM = 1;
    EXCEPTION 
     WHEN OTHERS THEN 
       nValidaMtoMaxPrima := 0;
    END;
    
  IF ACSELX.PR.Busca_Lval('SWITCH','MTOMAXPRIMA') = kSi AND nValidaMtoMaxPrima = 1 THEN
      BEGIN
        SELECT NVL(MtoMaxPrima,0) 
    INTO nMontoMaxPrima 
    FROM ACSELX.PLAN_FINANCIAMIENTO_INT C
        WHERE CodPlan = gCF12.CodPlan 
    AND ModPlan = gCF12.ModPlan 
    AND Tip_Tarj = 'C' 
    AND C.Estado = 'A';
      EXCEPTION 
      WHEN OTHERS THEN 
      nMontoMaxPrima := 0;
      END;
    
      IF nMontoMaxPrima > 0 AND gCF12.MtoPago > nMontoMaxPrima THEN
        P_ERROR('Monto Financiado NO puede ser MAYOR que '||nMontoMaxPrima||', segun Plan asociado.');
      END IF;
    
  END IF;
    -- Nivel de autorizacion: politicas violadas
    IF NVL(gC00_12.cIndTranscripcion,kNo) = kNo THEN
      IF gCF12.PorcInteres < nPorcInteres THEN
        nPorcMinimo := nPorcInteres; -- N3024767
        IF nPorcMinimo < gCF12.PorcInteres THEN
          
      DELETE ACSELX.POLITICA_VIOLADA_REFRA 
      WHERE NumRefinanc = gC00_12.nNumRefinanc 
      AND CodPolVio = '006';
          
      cDescPolVio := ACSELX.PR_Cond_Financiamiento2.Desc_Politica_Violada(gC00_12.nNumRefinanc);
          
      IF cDescPolVio IS NOT NULL THEN
            UPDATE ACSELX.TEXTO_POLITICA_VIOLADA
            SET    DescPolVio = SUBSTR(cDescPolVio,1,INSTR(cDescPolVio,'Se cambio Porc. Interes de',1)-1)||
                                SUBSTR(cDescPolVio,INSTR(cDescPolVio,CHR(10),INSTR(cDescPolVio,'Se cambio Porc. Interes de',1))+1)
            WHERE  NumRefinanc = gC00_12.nNumRefinanc;
          END IF;
        END IF;
      ELSIF gCF12.PorcInteres >= nPorcInteres THEN
        DELETE ACSELX.POLITICA_VIOLADA_REFRA 
    WHERE NumRefinanc = gC00_12.nNumRefinanc 
    AND CodPolVio = '006';
      END IF;
      IF gCF12.CantGiros <= nCantgiros THEN
        DELETE ACSELX.POLITICA_VIOLADA_REFRA 
    WHERE NumRefinanc = gC00_12.nNumRefinanc 
    AND CodPolVio = '007';
      END IF;
      
    SELECT COUNT(1) 
    INTO nCantPolVio 
    FROM ACSELX.POLITICA_VIOLADA_REFRA 
    WHERE NumRefinanc = gC00_12.nNumRefinanc;
      
    IF nCantPolVio > 0 THEN 
      nIndRefinanc := 1; 
    ELSE 
      nIndRefinanc := 0; 
    END IF;
    ELSE
      nIndRefinanc := 0;
    END IF;

    IF nIndRefinanc = 0 THEN
      UPDATE ACSELX.COND_FINANCIAMIENTO 
    SET IndFactPend = gC00_12.cIndFactPend 
    WHERE NumRefinanc = gC00_12.nNumRefinanc;
      -- RTC-230951: responsable de pago de la poliza (RESP_PAGO)
      P_LOG('PB_ACTUALIZAR_RESP_PAGO');
      ACSELX.PR_COND_FINANCIAMIENTO2.PB_ACTUALIZAR_RESP_PAGO(gC00_12.nNumOper, gC00_12.nNumRefinanc, Vc_Error);
      
    IF Vc_Error IS NOT NULL THEN
        P_ERROR('Error al actualizar el responsable de pago. (RESP_PAGO) '||Vc_Error);
      END IF;

      F12_FR_FINALIZAR_REFRA;

      BEGIN  -- N3019752 (asistencia medica)
        SELECT 1 
    INTO nExiste
        FROM   ACSELX.COND_FINANCIAMIENTO A, ACSELX.REC_FINANCIAMIENTO B, ACSELX.RECIBO C
        WHERE  A.NumRefinanc = gC00_12.nNumRefinanc 
    AND B.NumFinanc = A.NumFinanc 
    AND C.IdeRec = B.IdeRec
        AND  C.CodRamoCert IN (SELECT CodLval 
                           FROM ACSELX.LVAL 
                 WHERE TipoLval = 'RAMOASME');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN nExiste := 0;
        WHEN TOO_MANY_ROWS THEN nExiste := 1;
        WHEN OTHERS        THEN nExiste := 0;
      END;
      
    nExiSal := NULL; -- N3037254 (Rimac Salud)
      
    BEGIN
        SELECT NVL(MAX(1),0) 
    INTO nExiSal 
    FROM DUAL
        WHERE  EXISTS (SELECT 1 
                   FROM ACSELX.TRANSACRE T 
             WHERE AplicOrig = 'RS' 
             AND NumFinanc = gC00_12.nNumRefinanc);
      EXCEPTION 
       WHEN OTHERS THEN 
       nExiSal := 0;
      END;
      
    -- RTC-219899: re-enlace de NumRefracc via COND_FINANCIAMIENTO_AUX
      SELECT COUNT(1) 
    INTO nFinancOK 
    FROM ACSELX.COND_FINANCIAMIENTO C 
    WHERE C.NumRefracc = gC00_12.nNumRefinanc;
      
    IF NVL(nFinancOK,0) = 0 THEN
        SELECT C.NumFinanc 
    INTO nNumFinanc 
    FROM ACSELX.COND_FINANCIAMIENTO C 
    WHERE C.NumRefinanc = gC00_12.nNumRefinanc;
    
        FOR CFIN IN (SELECT DISTINCT C.NumFinanOld FROM ACSELX.COND_FINANCIAMIENTO_AUX C WHERE C.NumFinanc = nNumFinanc) LOOP
          UPDATE ACSELX.COND_FINANCIAMIENTO C SET NumReFracc = gC00_12.nNumRefinanc WHERE NumFinanc = CFIN.NumFinanOld;
        END LOOP;
      END IF;

      -- Control adicional del bloque (no existe en la forma): los documentos nuevos deben estar a nombre del asegurado
      SELECT COUNT(1) 
    INTO nFinancOK 
    FROM ACSELX.FACTURA
      WHERE  NumOper = gC00_12.nNumOper
      AND  NOT (NVL(TipoId,'#') = NVL(gCliAseg.TipoId,'#') 
    AND NumId = gCliAseg.NumId 
    AND NVL(DvId,'#') = NVL(gCliAseg.DvId,'#'));
    
      IF nFinancOK > 0 THEN
        P_ERROR('Hay '||nFinancOK||' documento(s) nuevo(s) que no estan a nombre del asegurado '||gCliAseg.CodCli);
      END IF;
      
    FOR f IN (SELECT NumFact, TipoDoc, StsFact, FecVencFact, MtoFactMoneda, CodMoneda
                FROM ACSELX.FACTURA 
        WHERE NumOper = gC00_12.nNumOper 
        ORDER BY FecVencFact, NumFact) LOOP
        P_LOG('   Nuevo documento '||f.TipoDoc||' '||f.NumFact||' '||f.StsFact||' vence '||
              TO_CHAR(f.FecVencFact,'dd/mm/yyyy')||' '||TO_CHAR(f.MtoFactMoneda,'FM999,999,990.00')||' '||f.CodMoneda);
      END LOOP;

      COMMIT;
      gCommit := TRUE;
      P_LOG('COMMIT realizado');

      BEGIN
        IF nExiSal >= 1 THEN
          ACSELX.PR_ITF_MIGR_DOC_RSALUD.ACTUALIZA_RS_FACT_REFINANC(gC00_12.nNumRefinanc,'FIN');
          P_LOG('ACTUALIZA_RS_FACT_REFINANC ejecutado');
        END IF;
      EXCEPTION WHEN 
       OTHERS THEN 
       P_AVISO('Error al enviar la informacion de RIMAC SALUD. '||SQLERRM);
      END;
      
    BEGIN
        IF nExiste = 1 THEN
          ACSELX.PR_Salud.Retorna_Financ(gC00_12.nNumRefinanc);
          P_LOG('PR_SALUD.RETORNA_FINANC ejecutado');
        END IF;
      EXCEPTION 
      WHEN OTHERS THEN 
    P_AVISO('Error al enviar la informacion de ASISTENCIA MEDICA. '||SQLERRM);
      END;
      
    COMMIT; -- FR_Commit_Form
      
    -- RTC-257384: :B02_1.NUMAUTORIZA (bloque AUTORIZA_DOC_PAGO_CLIENTE = Pago Facil; vacio en este caso)
      SELECT MAX(NumAutoriza) 
    INTO nNumAutoriza 
    FROM ACSELX.FINANC_DOC_PAGO_CLIENTE_T
      WHERE IdTipo = gC00_12.nNumRefinanc 
    AND IndTipo = 'R';
      
    F12_CONSULTAR_B03_1;
      
    BEGIN
        ACSELX.PR_COND_FINANCIAMIENTO2.PB_ACTUALIZAR_RS_CPR_CPMP(nNumAutoriza, gCF12.NumFinanc, gB01_1.CodCli, gCF12.TipoFin,
                                                                 gCF12.CantGiros, gB01_1.CodPlanFracc, gB01_1.NumRefinanc,
                                                                 Vc_Error);
        IF Vc_Error IS NOT NULL THEN
          ROLLBACK; 
      P_AVISO(Vc_Error);
        ELSE
          COMMIT; 
      P_LOG('PB_ACTUALIZAR_RS_CPR_CPMP ejecutado');
        END IF;
      EXCEPTION 
      WHEN OTHERS THEN 
       ROLLBACK; 
       P_AVISO('PB_ACTUALIZAR_RS_CPR_CPMP: '||SQLERRM);
      END;
      -- FR_Notes.Generar_Documento(:C00.nNumRefinanc): tramite en Lotus Notes del cliente Forms (no se replica)
      FIN_PASO('Re-Financiamiento definitivo generado con exito!!!');
    ELSE
      -- En la forma: GO_BLOCK('B05_1') -> solicitud de autorizacion por correo. No se replica.
      cDescPolVio := ACSELX.PR_Cond_Financiamiento2.Desc_Politica_Violada(gC00_12.nNumRefinanc);
      P_ERROR('El refinanciamiento viola '||nCantPolVio||' politica(s) y requiere autorizacion (bloque B05_1): '||
              REPLACE(SUBSTR(cDescPolVio,1,1500),CHR(10),' / '));
    END IF;
  END F12_ACEPTAR;

-- ===================================================================================================
-- PROGRAMA PRINCIPAL: recorrido del usuario
-- ===================================================================================================
BEGIN
  DBMS_OUTPUT.ENABLE(NULL);
  DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
  DBMS_OUTPUT.PUT_LINE('REFINANCIAMIENTO CON CAMBIO DE RESPONSABLE AL ASEGURADO Y CAMBIO DE PLAN - '||
                       TO_CHAR(SYSDATE,'dd/mm/yyyy hh24:mi:ss')||' - Usuario '||USER);
  DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
  SAVEPOINT sp_refinanciamiento;

  VALIDAR_PARAMETROS;                 -- 00
  -- FIN00010
  F10_INICIO_FORMA;                   -- 01 WHEN-NEW-FORM-INSTANCE P6
  F10_BT_DOC;                         -- 02 B01_Q.BT_DOC P25
  F10_FR_VALIDAR_NUMERO_FACTURA;      -- 03 B02_1.NUMFACT P35 + grabar TEMP_DOCS_FINANC
  F10_BT_ACEPTAR_DOCUMENTOS;          -- 04 B02_2.BT_ACEPTAR P39 (FR_Iniciar_Operacion_Refinanc)
  F10_SELECCIONAR_CERTIFICADO;        -- 05 B03_1.CSELECCION P60
  F10_SIGUIENTE_BLOQUE;               -- 06 B03_1 KEY-NXTBLK P51 (-> FIN00012)
  -- FIN00012
  F12_INICIO_FORMA;                   -- 07 WHEN-NEW-FORM-INSTANCE P6
  F12_CAMBIAR_RESPONSABLE;            -- 08 B01_1.CODCLI WHEN-VALIDATE-ITEM P27
  F12_CAMBIAR_PLAN;                   -- 09 B01_1.CODPLANFRACC P36/P33/P35
  F12_SIGUIENTE_BLOQUE;               -- 10 B01_1 KEY-NXTBLK P21 (FR_Fraccionar)
  F12_FR_RECALCULAR;                  -- 11 C03.RECALCULAR P88
  F12_MOTIVO;                         -- 12 C03.MOTIVO P91 / B04_1
  F12_ACEPTAR;                        -- 13 C03.ACEPTAR P90 (FR_Finalizar_Refra + COMMIT)

  gPaso := 'FIN';
  DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
  DBMS_OUTPUT.PUT_LINE('REFINANCIAMIENTO EXITOSO. Documento '||p_nNumFact||' -> NumRefinanc '||gC00_12.nNumRefinanc||
                       ' / NumOper '||gC00_12.nNumOper||' / financ nuevo '||gCF12.NumFinanc||
                       ' / responsable '||gB01_1.CodCli||' / plan '||gB01_1.CodPlanFracc||'-'||gB01_1.NumModPlanFracc||
                       ' ('||ROUND((DBMS_UTILITY.GET_TIME-gInicio)/100,1)||' s)');
  DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
    DBMS_OUTPUT.PUT_LINE('REFINANCIAMIENTO FALLIDO en el paso: '||gPaso);
    DBMS_OUTPUT.PUT_LINE('Motivo : '||SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Origen : '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    IF NOT gCommit THEN
      BEGIN
        ROLLBACK TO sp_refinanciamiento;
        DBMS_OUTPUT.PUT_LINE('Se deshicieron todos los cambios (ROLLBACK TO sp_refinanciamiento).');
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          DBMS_OUTPUT.PUT_LINE('ATENCION: no se pudo volver al savepoint ('||SQLERRM||'); se hizo ROLLBACK total.');
      END;
    ELSE
      DBMS_OUTPUT.PUT_LINE('El refinanciamiento YA estaba confirmado (COMMIT); el error ocurrio en las interfaces posteriores.');
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('=',120,'='));
END;
