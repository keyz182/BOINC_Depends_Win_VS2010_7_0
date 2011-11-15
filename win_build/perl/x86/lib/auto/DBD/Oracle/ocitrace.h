#ifndef DBD_OCI_TRACEON

/* OCI functions "wrapped" to produce tracefile dumps (may be handy when giving
  diagnostic info to Oracle Support, or just learning about OCI)
  Macros are named "_log" as a mnemonic that they log to the tracefile if needed
  Macros named "_log_stat" return status in last parameter.
*/

#define DBD_OCI_TRACEON	(DBIS->debug >= 6)
#define DBD_OCI_TRACEFP	(DBILOGFP)
#define OciTp		("\tOCI")		/* OCI Trace Prefix */
#define OciTstr(s)	((s) ? (text*)(s) : (text*)"<NULL>")
#define ul_t(v)		((unsigned long)(v))
#define pul_t(v)	((unsigned long *)(v))
#define sl_t(v)		((signed long)(v))
#define psl_t(v)	((signed long *)(v))

/* XXX TO DO

    1.	Add parenthesis around all macro args. (or do item 4 below case-by-case)
    DMG: Partly done, sort of. At least the types all match the doc'd casts, anyway.

    2.	#define a set of OciTxxx macros for different types of parameters
	that would allow
	a: casting to be hidden
	b: casting easily changed on different platforms (64bit etc)
	c: mapping of some type values to strings,
	d: return pointed-to value instead of pointer where applicable

   How to output arguments that are handles to opaque entities (OCIEnv*, etc)?
   Output of pointer address is a quick n' dirty way of identifying
   any number of handles that may be allocated.... yuck...
   It sure would be nice to give something more mnemonic! (and meaningful!)
   XXX Turn pointers into variable names by adding a prefix letter and, where
	appropriate an &, thus: "...,&p%ld,...",
	If done well the log will read like a compilable program.
*/



#define OCIXMLTypeCreateFromSrc_log_stat(svchp,envhp,src_type,src_ptr,xml,stat)\
    stat =OCIXMLTypeCreateFromSrc (svchp,envhp,(OCIDuration)OCI_DURATION_CALLOUT,(ub1)src_type,(dvoid *)src_ptr,(sb4)OCI_IND_NOTNULL, xml);\
    (DBD_OCI_TRACEON) \
    		? PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCIXMLTypeCreateFromSrc_log_stat(%p,%p,%p,%p,%p)=%s\n",\
		         OciTp,  (void*)svchp,(void*)envhp, src_type, src_ptr,oci_status_name(stat)),stat \
   : stat

#define OCILobLocatorIsInit_log_stat(envhp,errhp,loc,is_init,stat)\
    stat =OCILobLocatorIsInit (envhp,errhp,loc,is_init );\
    (DBD_OCI_TRACEON) \
    		? PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCILobLocatorIsInit_log_stat(%p,%p,%p,%d)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,loc,is_init,oci_status_name(stat)),stat \
   : stat

#define OCIObjectPin_log_stat(envhp,errhp,or,ot,stat)\
    stat = OCIObjectPin(envhp,errhp,or,(OCIComplexObject *)0,OCI_PIN_LATEST,OCI_DURATION_TRANS,OCI_LOCK_NONE,ot);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sObjectPin_log_stat(%p,%p,%p,%p)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,or,ot,oci_status_name(stat)),stat \
   : stat


#define OCICollGetElem_log_stat(envhp,errhp,v,i,ex,e,ne,stat)\
    stat = OCICollGetElem(envhp,errhp, v,i,ex,e,ne);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCICollGetElem_log_stat(%p,%p,%d,%d,%d,%d,%d)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,v,i,ex,e,ne,oci_status_name(stat)),stat \
   : stat


#define OCITableFirst_log_stat(envhp,errhp,v,i,stat)\
    stat = OCITableFirst(envhp,errhp,v,i);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCITableFirst_log_stat(%p,%p,%d,%d)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,v,i,oci_status_name(stat)),stat \
   : stat

#define OCIObjectGetAttr_log_stat(envhp,errhp,v,no,ot,tn,tnl,ani,ans,av,atdo, stat)\
    stat = OCIObjectGetAttr(errhp,errhp,v,no,ot,tn,tnl,1,(ub4 *)0, 0,ani,ans,av,atdo,stat);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCIObjectGetAttr_log_stat(%p,%p,%d,%d,%d,%d,%d,%d,%d,%d,%d)=%s\n",\
		         OciTp, (void*)envhp,(void*)errhp,v,no,ot,tn,tnl,ani,ans,av,atdo,(void*)errhp,oci_status_name(stat)),stat \
   : stat



#define OCIIntervalToText_log_stat(envhp,errhp,di,sb,ln,sl,stat)\
    stat = OCIIntervalToText(envhp,errhp, *(OCIInterval**)di,3,3,sb,ln,sl);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "% OCIIntervalToText(%p,%p,%p,%s)=%s\n",\
		         OciTp, (void*)errhp, di,sl,sb,oci_status_name(stat)),stat \
  : stat

#define OCIDateTimeToText_log_stat(envhp,errhp,d,sl,sb,stat)\
    stat = OCIDateTimeToText(envhp,errhp, *(OCIDateTime**)d,(CONST text*) 0,(ub1) 0,0, (CONST text*) 0, (ub4) 0,(ub4 *)sl,sb );\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "% OCIDateTimeToText(%p,%p,%p,%s)=%s\n",\
		         OciTp, (void*)errhp, d,sl,sb,oci_status_name(stat)),stat \
  : stat


#define OCIDateToText_log_stat(errhp,d,sl,sb,stat)\
    stat = OCIDateToText(errhp, (CONST OCIDate *) d,(CONST text*) 0,(ub1) 0, (CONST text*) 0, (ub4) 0,(ub4 *)sl,sb );\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sDateToText_log_stat(%p,%p,%p,%s)=%s\n",\
		         OciTp, (void*)errhp, d,sl,sb,oci_status_name(stat)),stat \
  : stat


#define OCIIterDelete_log_stat(envhp,errhp,itr,stat)\
	stat = OCIIterDelete(envhp,errhp,itr );\
	(DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCIIterDelete_log_stat(%p,%p,%d)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,itr,oci_status_name(stat)),stat \
   : stat


#define OCIIterCreate_log_stat(envhp,errhp,coll,itr,stat)\
    stat = OCIIterCreate(envhp,errhp,coll,itr);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sIterCreate_log_stat(%p,%p,%p)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,(void*)coll,oci_status_name(stat)),stat \
   : stat

#define OCICollSize_log_stat(envhp,errhp,coll,coll_siz,stat)\
    stat = OCICollSize(envhp,errhp,(CONST OCIColl *)coll,coll_siz);\
    (DBD_OCI_TRACEON) \
		   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
		         "%sOCICollSize_log_stat(%p,%p,%d)=%s\n",\
		         OciTp, (void*)envhp, (void*)errhp,oci_status_name(stat)),stat \
   : stat

#define OCIDefineObject_log_stat(defnp,errhp,tdo,eo_buff,eo_ind,stat)\
    stat = OCIDefineObject(defnp,errhp,tdo,eo_buff,0,eo_ind, 0);\
    (DBD_OCI_TRACEON) \
	   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
	         "%sOCIDefineObject(%p,%p,%d)=%s\n",\
	         OciTp, (void*)defnp, (void*)errhp, (void*)tdo,oci_status_name(stat)),stat \
   : stat

#define OCITypeByName_log_stat(envhp,errhp,svchp,p1,l,tdo,stat)\
    stat = OCITypeByName(envhp,errhp,svchp,(const oratext*)"",0,p1,l,0,0,OCI_DURATION_TRANS,OCI_TYPEGET_ALL,tdo);\
    (DBD_OCI_TRACEON) \
	   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
	         "%sTypeByName(%p,%p,%p,%s,%d)=%s\n",\
	         OciTp, (void*)envhp, (void*)errhp, (void*)svchp, (char*)(p1),(l),oci_status_name(stat)),stat \
   : stat

/* added by lab */
#define OCILobCharSetId_log_stat( envhp, errhp, locp, csidp, stat ) \
   stat = OCILobCharSetId( envhp, errhp, locp, csidp ); \
	(DBD_OCI_TRACEON) \
   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
         "%sLobCharSetId(%p,%p,%p,%d)=%s\n",\
         OciTp, (void*)envhp, (void*)errhp, (void*)locp, *csidp, oci_status_name(stat)),stat \
   : stat

/* added by lab */
#define OCILobCharSetForm_log_stat( envhp, errhp, locp, formp, stat ) \
   stat = OCILobCharSetForm( envhp, errhp, locp, formp ); \
	(DBD_OCI_TRACEON) \
   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
         "%sLobCharSetForm(%p,%p,%p,%d)=%s\n",\
         OciTp, (void*)envhp, (void*)errhp, (void*)locp, *formp, oci_status_name(stat)),stat \
   : stat

/* added by lab */
#define OCINlsEnvironmentVariableGet_log_stat( valp, size, item, charset, rsizep ,stat ) \
   stat = OCINlsEnvironmentVariableGet(  valp, size, item, charset, rsizep ); \
	(DBD_OCI_TRACEON) \
   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
         "%sNlsEnvironmentVariableGet(%d,%d,%d,%d,%d)=%s\n",\
         OciTp, *valp, size, item, charset, *rsizep, oci_status_name(stat)),stat \
   : stat

/* added by lab */
#define OCIEnvNlsCreate_log_stat( envp, mode, ctxp, f1, f2, f3, sz, usremepp ,chset, nchset ,stat ) \
   stat = OCIEnvNlsCreate(envp, mode, ctxp, f1, f2, f3, sz, usremepp ,chset, nchset ); \
	(DBD_OCI_TRACEON) \
   ?  PerlIO_printf(DBD_OCI_TRACEFP,\
         "%sNlsEnvCreate(%p,%d,%d,%p,%p,%p,%d,%p,%d,%d)=%s\n", \
         OciTp, (void*)envp, mode, ctxp, (void*)f1, (void*)f2, (void*)f3, sz, (void*)usremepp ,chset, nchset, oci_status_name(stat)),stat \
   : stat


#define OCIAttrGet_log_stat(th,ht,ah,sp,at,eh,stat)                    \
	stat = OCIAttrGet(th,ht,ah,sp,at,eh);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sAttrGet(%p,%s,%p,%p,%lu,%p)=%s\n",			\
	  OciTp, (void*)th,oci_hdtype_name(ht),(void*)ah,pul_t(sp),ul_t(at),(void*)eh,\
	  oci_status_name(stat)),stat : stat

 #define OCIAttrGet_parmap(imp_sth,dh, ht, p1, l, stat)              \
		  	OCIAttrGet_log_stat(dh, ht,			\
		(void*)(p1), (l), OCI_ATTR_PARAM, imp_sth->errhp, stat)


#define OCIAttrGet_parmdp(imp_sth, parmdp, p1, l, a, stat)              \
	OCIAttrGet_log_stat(parmdp, OCI_DTYPE_PARAM,			\
		(void*)(p1), (l), (a), imp_sth->errhp, stat)

#define OCIAttrGet_stmhp_stat(imp_sth, p1, l, a, stat)                  \
	OCIAttrGet_log_stat(imp_sth->stmhp, OCI_HTYPE_STMT,		\
		(void*)(p1), (l), (a), imp_sth->errhp, stat)

#define OCIAttrSet_log_stat(th,ht,ah,s1,a,eh,stat)                      \
	stat=OCIAttrSet(th,ht,ah,s1,a,eh);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sAttrSet(%p,%s,%p,%lu,%lu,%p)=%s\n",			\
	  OciTp, (void*)th,oci_hdtype_name(ht),(void*)(ah),ul_t(s1),ul_t(a),(void*)eh,	\
	  oci_status_name(stat)),stat : stat

#define OCIBindByName_log_stat(sh,bp,eh,p1,pl,v,vs,dt,in,al,rc,mx,cu,md,stat)  \
	stat=OCIBindByName(sh,bp,eh,p1,pl,v,vs,dt,in,al,rc,mx,cu,md);	\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sBindByName(%p,%p,%p,\"%s\",placeh_len=%ld,value_p=%p,value_sz=%ld," \
	  "dty=%u,indp=%p,alenp=%p,rcodep=%p,maxarr_len=%lu,curelep=%p (*=%d),mode=%lu)=%s\n",\
 	  OciTp, (void*)sh,(void*)bp,(void*)eh,p1,sl_t(pl),(void*)(v),	\
	  sl_t(vs),(ub2)(dt),(void*)(in),(ub2*)(al),(ub2*)(rc),		\
	  ul_t((mx)),pul_t((cu)),(cu ? *(int*)cu : 0 ) ,ul_t((md)),				\
	  oci_status_name(stat)),stat : stat

#define	OCIBindArrayOfStruct_log_stat(bp,ep,sd,si,sl,sr,stat)	\
	stat=OCIBindArrayOfStruct(bp,ep,sd,si,sl,sr);		\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,	\
	  "%sOCIBindArrayOfStruct(%p,%p,%u,%u,%u,%u)=%s\n",	\
	  OciTp,(void*)bp,(void*)ep,sd,si,sl,sr,		\
	  oci_status_name(stat)),stat : stat

#define OCIBindDynamic_log(bh,eh,icx,cbi,ocx,cbo,stat)                 \
	stat=OCIBindDynamic(bh,eh,icx,cbi,ocx,cbo);			\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sBindDynamic(%p,%p,%p,%p,%p,%p)=%s\n",			\
	  OciTp, (void*)bh,(void*)eh,(void*)icx,(void*)cbi,		\
	  (void*)ocx,(void*)cbo,					\
	  oci_status_name(stat)),stat : stat

#define OCIDefineByPos_log_stat(sh,dp,eh,p1,vp,vs,dt,ip,rp,cp,m,stat)   \
	stat=OCIDefineByPos(sh,dp,eh,p1,vp,vs,dt,ip,rp,cp,m);		\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sDefineByPos(%p,%p,%p,%lu,%p,%ld,%u,%p,%p,%p,%lu)=%s\n",	\
	  OciTp, (void*)sh,(void*)dp,(void*)eh,ul_t((p1)),(void*)(vp),	\
	  sl_t(vs),(ub2)dt,(void*)(ip),(ub2*)(rp),(ub2*)(cp),ul_t(m),	\
	  oci_status_name(stat)),stat : stat

#define OCIDescribeAny_log_stat(sh,eh,op,ol,opt,il,ot,dh,stat)         \
	stat=OCIDescribeAny(sh,eh,op,ol,opt,il,ot,dh);			\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sDescribeAny(%p,%p,%p,%lu,%u,%u,%u,%p)=%s\n",     		\
	  OciTp, (void*)sh,(void*)eh,(void*)op,ul_t(ol),		\
	  (ub1)opt,(ub1)il,(ub1)ot,(void*)dh,				\
	  oci_status_name(stat)),stat : stat

#define OCIDescriptorAlloc_ok(envhp, p1, t)                             \
	if (DBD_OCI_TRACEON) PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sDescriptorAlloc(%p,%p,%s,0,0)\n",        			\
	  OciTp,(void*)envhp,(void*)(p1),oci_hdtype_name(t));			\
	if (OCIDescriptorAlloc((envhp), (void**)(p1), (t), 0, 0)==OCI_SUCCESS);	\
	else croak("OCIDescriptorAlloc (type %ld) failed",t)

#define OCIDescriptorFree_log(d,t)                                     \
	if (DBD_OCI_TRACEON) PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sDescriptorFree(%p,%s)\n", OciTp, (void*)d,oci_hdtype_name(t));	\
	OCIDescriptorFree(d,t)

#define OCIEnvInit_log_stat(ev,md,xm,um,stat)                          \
	stat=OCIEnvInit(ev,md,xm,um);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sEnvInit(%p,%lu,%lu,%p)=%s\n",				\
	  OciTp, (void*)ev,ul_t(md),ul_t(xm),(void*)um,			\
	  oci_status_name(stat)),stat : stat

#define OCIErrorGet_log_stat(hp,rn,ss,ep,bp,bs,t, stat)			\
	((stat = OCIErrorGet(hp,rn,ss,ep,bp,bs,t)),			\
	((DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sErrorGet(%p,%lu,\"%s\",%p,\"%s\",%lu,%lu)=%s\n",		\
	  OciTp, (void*)hp,ul_t(rn),OciTstr(ss),psl_t(ep),		\
	  bp,ul_t(bs),ul_t(t), oci_status_name(stat)),stat : stat))

#define OCIHandleAlloc_log_stat(ph,hp,t,xs,ump,stat)                   \
	stat=OCIHandleAlloc(ph,hp,t,xs,ump);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sHandleAlloc(%p,%p,%s,%lu,%p)=%s\n",			\
	  OciTp, (void*)ph,(void*)hp,oci_hdtype_name(t),ul_t(xs),(void*)ump,	\
	  oci_status_name(stat)),stat : stat

#define OCIHandleAlloc_ok(envhp, p1, t, stat)                           \
	OCIHandleAlloc_log_stat((envhp),(void**)(p1),(t),0,0, stat);	\
	if (stat==OCI_SUCCESS) ;					\
	else croak("OCIHandleAlloc(%s) failed",oci_hdtype_name(t))

#define OCIHandleFree_log_stat(hp,t,stat)                              \
	stat=OCIHandleFree(  (hp), (t));				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sHandleFree(%p,%s)=%s\n",OciTp,(void*)hp,oci_hdtype_name(t),		\
	  oci_status_name(stat)),stat : stat

#define OCIInitialize_log_stat(md,cp,mlf,rlf,mfp,stat)                 \
	stat=OCIInitialize(md,cp,mlf,rlf,mfp);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sInitialize(%lu,%p,%p,%p,%p)=%s\n",				\
	  OciTp, ul_t(md),(void*)cp,(void*)mlf,(void*)rlf,(void*)mfp,	\
	  oci_status_name(stat)),stat : stat

#define OCILobGetLength_log_stat(sh,eh,lh,l,stat)                      \
	stat=OCILobGetLength(sh,eh,lh,l);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobGetLength(%p,%p,%p,%p)=%s\n",				\
	  OciTp, (void*)sh,(void*)eh,(void*)lh,pul_t(l),		\
	  oci_status_name(stat)),stat : stat

#define OCILobFileOpen_log_stat(sv,eh,lh,mode,stat) \
	stat=OCILobFileOpen(sv,eh,lh,mode);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobFileOpen(%p,%p,%p,%u)=%s\n",				\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,(ub1)mode,		\
	  oci_status_name(stat)),stat : stat

#define OCILobFileClose_log_stat(sv,eh,lh,stat) \
	stat=OCILobFileClose(sv,eh,lh);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobFileClose(%p,%p,%p)=%s\n",				\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,				\
	  oci_status_name(stat)),stat : stat
/*Added by JPS for Jeffrey.Klein*/

#if !defined(ORA_OCI_8)
#define OCILobCreateTemporary_log_stat(sv,eh,lh,csi,csf,lt,ca,dur,stat) \
	stat=OCILobCreateTemporary(sv,eh,lh,csi,csf,lt,ca,dur);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobCreateTemporary(%p,%p,%p,%lu,%lu,%lu,%lu,%lu)=%s\n",				\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,				\
          ul_t(csi),ul_t(csf),ul_t(lt),ul_t(ca),ul_t(dur), \
	  oci_status_name(stat)),stat : stat
#else
#define OCILobCreateTemporary_log_stat(sv,eh,lh,stat) \
    stat=0 /* Actually, this should be a compile error */
#endif

/*end add*/

#if !defined(ORA_OCI_8)
#define OCILobFreeTemporary_log_stat(sv,eh,lh,stat) \
	stat=OCILobFreeTemporary(sv,eh,lh);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobFreeTemporary(%p,%p,%p)=%s\n",				\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,				\
	  oci_status_name(stat)),stat : stat
#else
#define OCILobFreeTemporary_log_stat(sv,eh,lh,stat) \
    stat=0
#endif

#if !defined(ORA_OCI_8)
#define OCILobIsTemporary_log_stat(ev,eh,lh,istemp,stat)                           \
	stat=OCILobIsTemporary(ev,eh,lh,istemp);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobIsTemporary(%p,%p,%p,%p)=%s\n",				\
	  OciTp, (void*)ev,(void*)eh,(void*)lh,(void*)istemp,		\
	  oci_status_name(stat)),stat : stat
#else
#define OCILobIsTemporary_log_stat(ev,eh,lh,istemp,stat) \
    stat=0
#endif
/*Added by JPS for Jeffrey.Klein */

#define OCILobLocatorAssign_log_stat(sv,eh,src,dest,stat) \
        stat=OCILobLocatorAssign(sv,eh,src,dest); \
        (DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP, \
        "%sLobLocatorAssign(%p,%p,%p,%p)=%s\n", \
       OciTp,(void*)sv,(void*)eh,(void*)src,(void*)dest, \
        oci_status_name(stat)),stat : stat

/*end add*/

#define OCILobRead_log_stat(sv,eh,lh,am,of,bp,bl,cx,cb,csi,csf,stat)   \
	stat=OCILobRead(sv,eh,lh,am,of,bp,bl,cx,cb,csi,csf);		\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobRead(%p,%p,%p,%p,%lu,%p,%lu,%p,%p,%u,%u)=%s\n",		\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,pul_t(am),ul_t(of),	\
	  (void*)bp,ul_t(bl),(void*)cx,(void*)cb,(ub2)csi,(ub1)csf,	\
	  oci_status_name(stat)),stat : stat

#define OCILobTrim_log_stat(sv,eh,lh,l,stat)                           \
	stat=OCILobTrim(sv,eh,lh,l);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobTrim(%p,%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,ul_t(l),			\
	  oci_status_name(stat)),stat : stat

#define OCILobWrite_log_stat(sv,eh,lh,am,of,bp,bl,p1,cx,cb,csi,csf,stat) \
	stat=OCILobWrite(sv,eh,lh,am,of,bp,bl,p1,cx,cb,csi,csf);		\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobWrite(%p,%p,%p,%p,%lu,%p,%lu,%u,%p,%p,%u,%u)=%s\n",	\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,pul_t(am),ul_t(of),	\
	  (void*)bp,ul_t(bl),(ub1)p1,					\
	  (void*)cx,(void*)cb,(ub2)csi,(ub1)csf,			\
	  oci_status_name(stat)),stat : stat

#define OCILobWriteAppend_log_stat(sv,eh,lh,am,bp,bl,p1,cx,cb,csi,csf,stat) \
	stat=OCILobWriteAppend(sv,eh,lh,am,bp,bl,p1,cx,cb,csi,csf);		\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sLobWriteAppend(%p,%p,%p,%p,%p,%lu,%u,%p,%p,%u,%u)=%s\n",	\
	  OciTp, (void*)sv,(void*)eh,(void*)lh,pul_t(am),	\
	  (void*)bp,ul_t(bl),(ub1)p1,					\
	  (void*)cx,(void*)cb,(ub2)csi,(ub1)csf,			\
	  oci_status_name(stat)),stat : stat

#define OCIParamGet_log_stat(hp,ht,eh,pp,ps,stat)                      \
	stat=OCIParamGet(hp,ht,eh,pp,ps);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sParamGet(%p,%lu,%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)hp,ul_t((ht)),(void*)eh,(void*)pp,ul_t(ps),	\
	  oci_status_name(stat)),stat : stat

#define OCIServerAttach_log_stat(imp_dbh, dbname,stat)                 \
	stat=OCIServerAttach( imp_dbh->srvhp, imp_dbh->errhp,		\
	  (text*)dbname, (sb4)strlen(dbname), 0);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sServerAttach(%p, %p, \"%s\", %d, 0)=%s\n",			\
	  OciTp, (void*)imp_dbh->srvhp,(void*)imp_dbh->errhp, dbname,	\
	  strlen(dbname), oci_status_name(stat)),stat : stat

#define OCIStmtExecute_log_stat(sv,st,eh,i,ro,si,so,md,stat)           \
	stat=OCIStmtExecute(sv,st,eh,i,ro,si,so,md);			\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sStmtExecute(%p,%p,%p,%lu,%lu,%p,%p,%lu)=%s\n",		\
	  OciTp, (void*)sv,(void*)st,(void*)eh,ul_t((i)),		\
	  ul_t((ro)),(void*)(si),(void*)(so),ul_t((md)),		\
	  oci_status_name(stat)),stat : stat
#if !defined(USE_ORA_OCI_STMNT_FETCH)
 #define OCIStmtFetch_log_stat(sh,eh,nr,or,os,stat)                     \
         stat=OCIStmtFetch2(sh,eh,nr,or,os,OCI_DEFAULT);                                \
         (DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,                        \
           "%sStmtFetch(%p,%p,%lu,%u,%lu)=%s\n",                                \
           OciTp, (void*)sh,(void*)eh,ul_t(nr),(ub2)or,(ub2)os,                \
           oci_status_name(stat)),stat : stat
#else
#define OCIStmtFetch_log_stat(sh,eh,nr,or,os,stat)                     \
        stat=OCIStmtFetch(sh,eh,nr,or,OCI_DEFAULT);                                \
        (DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,                        \
          "%sStmtFetch(%p,%p,%lu,%lu)=%s\n",                                \
          OciTp, (void*)sh,(void*)eh,ul_t(nr),(ub2)or,                \
          oci_status_name(stat)),stat : stat
#endif

#define OCIStmtPrepare_log_stat(sh,eh,s1,sl,l,m,stat)                   \
	stat=OCIStmtPrepare(sh,eh,s1,sl,l,m);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sStmtPrepare(%p,%p,'%s',%lu,%lu,%lu)=%s\n",			\
	  OciTp, (void*)sh,(void*)eh,s1,ul_t(sl),ul_t(l),ul_t(m),	\
	  oci_status_name(stat)),stat : stat

#define OCIServerDetach_log_stat(sh,eh,md,stat)                        \
	stat=OCIServerDetach(sh,eh,md);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sServerDetach(%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)sh,(void*)eh,ul_t(md),				\
	  oci_status_name(stat)),stat : stat

#define OCISessionBegin_log_stat(sh,eh,uh,cr,md,stat)                  \
	stat=OCISessionBegin(sh,eh,uh,cr,md);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sSessionBegin(%p,%p,%p,%lu,%lu)=%s\n",			\
	  OciTp, (void*)sh,(void*)eh,(void*)uh,ul_t(cr),ul_t(md),	\
	  oci_status_name(stat)),stat : stat

#define OCISessionEnd_log_stat(sh,eh,ah,md,stat)                       \
	stat=OCISessionEnd(sh,eh,ah,md);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sSessionEnd(%p,%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)sh,(void*)eh,(void*)ah,ul_t(md),		\
	  oci_status_name(stat)),stat : stat

#define OCITransCommit_log_stat(sh,eh,md,stat)                         \
	stat=OCITransCommit(sh,eh,md);					\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sTransCommit(%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)sh,(void*)eh,ul_t(md),				\
	  oci_status_name(stat)),stat : stat

#define OCITransRollback_log_stat(sh,eh,md,stat)                       \
	stat=OCITransRollback(sh,eh,md);				\
	(DBD_OCI_TRACEON) ? PerlIO_printf(DBD_OCI_TRACEFP,			\
	  "%sTransRollback(%p,%p,%lu)=%s\n",				\
	  OciTp, (void*)sh,(void*)eh,ul_t(md),				\
	  oci_status_name(stat)),stat : stat

#endif /* !DBD_OCI_TRACEON */
