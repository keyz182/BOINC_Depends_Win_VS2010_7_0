/*
   Copyright (c) 1994-2006 Tim Bunce

   See the COPYRIGHT section in the Oracle.pm file for terms.

*/

/* ====== define data types ====== */

typedef struct imp_fbh_st imp_fbh_t;


struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
    OCIEnv *envhp;
    int proc_handles;           /* If true, the envhp handle is owned by ProC
                                   and must not be freed. */
    SV *ora_long;
    SV *ora_trunc;
    SV *ora_cache;
    SV *ora_cache_o;		/* for ora_open() cache override */
};


/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t com;		/* MUST be first element in structure	*/

#ifdef USE_ITHREADS
    int refcnt ;        /* keep track of duped handles. MUST be first after com */
    struct imp_dbh_st * shared_dbh ; /* pointer to shared space from which to dup and keep refcnt */
    SV *                shared_dbh_priv_sv ;
#endif

    void *(*get_oci_handle) _((imp_dbh_t *imp_dbh, int handle_type, int flags));
    OCIEnv *envhp;		/* copy of drh pointer	*/
    OCIError *errhp;
    OCIServer *srvhp;
    OCISvcCtx *svchp;
    OCISession *authp;
    int proc_handles;           /* If true, srvhp, svchp, and authp handles
                                   are owned by ProC and must not be freed. */
    int RowCacheSize;
    int ph_type;		/* default oratype for placeholders */
    ub1 ph_csform;		/* default charset for placeholders */
    int parse_error_offset;	/* position in statement of last error */
    int max_nested_cursors;     /* limit on cached nested cursors per stmt */
    int array_chunk_size;  /* the max size for an array bind */

};

#define DBH_DUP_OFF sizeof(dbih_dbc_t)
#define DBH_DUP_LEN (sizeof(struct imp_dbh_st) - sizeof(dbih_dbc_t))


typedef struct lob_refetch_st lob_refetch_t; /* Define sth implementor data structure */


/*statement structure */
struct imp_sth_st {

    dbih_stc_t com;		/* MUST be first element in structure	*/

    void *(*get_oci_handle) _((imp_sth_t *imp_sth, int handle_type, int flags));
    OCIEnv			*envhp;	/* copy of dbh pointer	*/
    OCIError		*errhp;	/* copy of dbh pointer	*/
    OCIServer		*srvhp;	/* copy of dbh pointer	*/
    OCISvcCtx		*svchp;	/* copy of dbh pointer	*/
    OCIStmt			*stmhp;	/* oci statement  handle */
    OCIDescribe 	*dschp; /* oci describe handle */
   	ub2 			stmt_type;	/* OCIAttrGet OCI_ATTR_STMT_TYPE	*/
    U16				auto_lob;	/* use auto lobs*/
    int				pers_lob;   /*use dblink for lobs only for 10g Release 2. or later*/
    int  			has_lobs;   /* Statement has bound LOBS*/

    lob_refetch_t *lob_refetch;
    int  		nested_cursor; /* cursors fetched from SELECTs */
    AV          *bind_tuples;  /* Bind tuples in array execute, or NULL */
    int         rowwise;       /* If true, bind_tuples is list of */
		                       /* tuples, otherwise list of columns. */

    /* Input Details	*/
    char		*statement;		/* sql (see sth_scan)		*/
    HV        	*all_params_hv;	/* all params, keyed by name	*/
    AV        	*out_params_av;	/* quick access to inout params	*/
    int       	ora_pad_empty;	/* convert ""->" " when binding	*/

    /* Select Column Output Details	*/
    int       	done_desc;  	/* have we described this sth yet ?	*/
    imp_fbh_t 	*fbh;	    	/* array of imp_fbh_t structs	*/
    char      	*fbh_cbuf;  	/* memory for all field names       */
    int       	t_dbsize;     	/* raw data width of a row		*/
    UV        	long_readlen; 	/* local copy to handle oraperl	*/
    HV        	*fbh_tdo_hv;  	 /* hash of row #(0 based) and tdo object name from ora_oci_type_names hash */
     /* Select Row Cache Details */
    sb4       	cache_rows;
    int       	in_cache;
    int       	next_entry;
    int       	eod_errno;
    int      	est_width;    /* est'd avg row width on-the-wire	*/
    /* (In/)Out Parameter Details */
    bool  		has_inout_params;
    /* execute mode*/
    /* will be using this alot later me thinks  */
    ub4         exe_mode;
    /* fetch scrolling values */
    int 		fetch_orient;
    int			fetch_offset;
    int			fetch_position;
    int 		prefetch_memory;   /* OCI_PREFETCH_MEMORY*/
    /* array fetch: state variables */
    bool      rs_array_on;           /* if array to be used */
    int       rs_array_size;         /* array size */
    int       rs_array_num_rows;     /* num rows in last fetch */
    int       rs_array_idx;          /* index of current row */
    sword     rs_array_status;       /* status of last fetch */
};
#define IMP_STH_EXECUTING	0x0001


typedef struct fb_ary_st fb_ary_t;    /* field buffer array	*/
struct fb_ary_st { 	/* field buffer array EXPERIMENTAL	*/
    ub2  bufl;		/* length of data buffer		*/
    sb2  *aindp;	/* null/trunc indicator variable	*/
    ub1  *abuf;		/* data buffer (points to sv data)	*/
    ub2  *arlen;	/* length of returned data		*/
    ub2  *arcode;	/* field level error status		*/
};


typedef struct fbh_obj_st fbh_obj_t; /*Ebbedded Object Descriptor */

struct fbh_obj_st {  /* embedded object or table will work recursively*/
	text        	*type_name;    		/*object's name (TDO)*/
    ub4         	type_namel;    		/*length of the name*/
    OCIParam    	*parmdp;            /*Describe attributes of the object OCI_DTYPE_PARAM*/
	OCIParam    	*parmap;            /*Describe attributes of the object OCI_ATTR_COLLECTION_ELEMENT OCI_ATTR_PARAM*/
 	OCIType     	*tdo;				/*object's TDO handle */
	OCITypeCode 	typecode;			/*object's OOCI_ATTR_TYPECODE */
	OCITypeCode 	col_typecode;    	/*if collection this is its OCI_ATTR_COLLECTION_TYPECODE */
    OCITypeCode 	element_typecode;	/*if collection this is its element's OCI_ATTR_TYPECODE*/
	OCIRef      	*obj_ref;			/*if an embeded object this is ref handle to its TDO*/
	OCIInd		    *obj_ind;			/*Null indictator for object */
 	OCIComplexObject *obj_value;        /*the actual value from the DB*/
 	OCIType      	*obj_type;         	/*if an embeded object this is the  OCIType returned by a OCIObjectPin*/
    fbh_obj_t       *fields;			/*one object for each field/property*/
    int             field_count;		/*The number of fields Not really needed but nice to have*/
    AV				*value;				/*The value to send back to Perl This way there are no memory leaks*/
};

struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
    imp_sth_t *imp_sth;	/* 'parent' statement	*/
    int field_num;	/* 0..n-1		*/

    /* Oracle's description of the field	*/
    OCIParam  	*parmdp;
    OCIDefine 	*defnp;
    void 		*desc_h;	/* descriptor if needed (LOBs etc)	*/
    ub4  		desc_t;	/* OCI type of descriptor		*/
    int  		(*fetch_func) _((SV *sth, imp_fbh_t *fbh, SV *dest_sv));
    void 		(*fetch_cleanup) _((SV *sth, imp_fbh_t *fbh));
    ub2  		dbtype;	/* actual type of field (see ftype)	*/
    ub2  		dbsize;
    ub2  		prec;		/* XXX docs say ub1 but ub2 is needed	*/
    sb1  		scale;
    ub1  		nullok;
    char 		*name;
    SV   		*name_sv;	/* only set for OCI8			*/
    /* OCI docs say OCI_ATTR_CHAR_USED is ub4, they're wrong	*/
    ub1  		len_char_used;	/* OCI_ATTR_CHAR_USED			*/
    ub2  		len_char_size;	/* OCI_ATTR_CHAR_SIZE			*/
    ub2  		csid;		/* OCI_ATTR_CHARSET_ID			*/
    ub1  		csform;	/* OCI_ATTR_CHARSET_FORM		*/

    sb4  		disize;	/* max display/buffer size		*/
    char 		*bless;	/* for Oracle::OCI style handle data	*/
    void 		*special;	/* hook for special purposes (LOBs etc)	*/

    /* Our storage space for the field data as it's fetched	*/
    sword  		ftype;	/* external datatype we wish to get	*/
    fb_ary_t 	*fb_ary ;	/* field buffer array			*/
    /* if this is an embedded object we use this */
    fbh_obj_t   *obj;

 };

 /* Placeholder structure */
 /* Note: phs_t is serialized into scalar value, and de-serialized then. */
 /* Be carefull! */

typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st {  	/* scalar placeholder EXPERIMENTAL	*/
    imp_sth_t *imp_sth; /* 'parent' statement  			*/
    sword ftype;	/* external OCI field type		*/

    SV	*sv;		/* the scalar holding the value		*/
    U32 sv_type;	/* original sv type at time of bind	*/
    ub2 csid_orig;	/* original oracle default csid 	*/
    ub2 csid;		/* 0 for automatic			*/
    ub1 csform;		/* 0 for automatic			*/
    ub4 maxdata_size;	/* set OCI_ATTR_MAXDATA_SIZE if >0	*/
    bool is_inout;

    IV  maxlen;		/* max possible len (=allocated buffer)	*/
					/* Note: for array bind = buffer for each entry */
    OCIBind *bndhp;
    void *desc_h;	/* descriptor if needed (LOBs etc)	*/
    ub4   desc_t;	/* OCI type of desc_h			*/
    ub4   alen;
    ub2 arcode;
    int   idx;      /* 0-based index for ?/:1 style, or -1  */

    sb2 indp;		/* null indicator			*/
    char *progv;

    int (*out_prepost_exec)_((SV *, imp_sth_t *, phs_t *, int pre_exec));
    SV	*ora_field;		/* from attribute (for LOB binds)	*/
    ub4 alen_incnull;	/* 0 or 1 if alen should include null	*/
    /* Array bind support */
    char   * array_buf;            /* Temporary buffer = malloc(array_buflen) */
	int      array_buflen;         /* Allocated length of array_buf */
	int      array_numstruct;      /* Number of bound structures in buffer */
	OCIInd * array_indicators;     /* Indicator array       = malloc( array_numallocated * sizeof(OCIInd) ) */
	unsigned short *array_lengths; /* Array entries lengths = malloc( array_numallocated * sizeof(unsigned short) ) */
	int      array_numallocated;   /* Allocated number of indicators/lengths */
	int      ora_maxarray_numentries; /* Number of entries to send allocated to Oracle. (may be less, than total allocated) */

	/* Support for different internal C-types, representing Oracle data */
	int ora_internal_type; /* Which C-type would be bound instead of SQLT_CHR. */

   char name[1];	/* struct is malloc'd bigger as needed	*/
};


/* ------ define functions and external variables ------ */

extern int ora_fetchtest;

extern ub2 charsetid;
extern ub2 ncharsetid;
extern ub2 utf8_csid;
extern ub2 al32utf8_csid;
extern ub2 al16utf16_csid;

#define CS_IS_UTF8( cs ) \
   (  ( cs == utf8_csid ) || ( cs == al32utf8_csid ) )

#define CS_IS_UTF16( cs ) ( cs == al16utf16_csid )

#define CSFORM_IMPLIED_CSID(csform) \
    ((csform==SQLCS_NCHAR) ? ncharsetid : charsetid)

#define CSFORM_IMPLIES_UTF8(csform) \
    CS_IS_UTF8( CSFORM_IMPLIED_CSID( csform ) )


void dbd_init_oci _((dbistate_t *dbistate));
void dbd_preparse _((imp_sth_t *imp_sth, char *statement));
void dbd_fbh_dump(imp_fbh_t *fbh, int i, int aidx);
void ora_free_fbh_contents _((imp_fbh_t *fbh));
void ora_free_templob _((SV *sth, imp_sth_t *imp_sth, OCILobLocator *lobloc));
int ora_dbtype_is_long _((int dbtype));
fb_ary_t *fb_ary_alloc _((int bufl, int size));
int ora_db_reauthenticate _((SV *dbh, imp_dbh_t *imp_dbh, char *uid, char *pwd));

void dbd_phs_sv_complete _((phs_t *phs, SV *sv, I32 debug));
void dbd_phs_avsv_complete _((phs_t *phs, I32 index, I32 debug));

int pp_exec_rset _((SV *sth, imp_sth_t *imp_sth, phs_t *phs, int pre_exec));
int pp_rebind_ph_rset_in _((SV *sth, imp_sth_t *imp_sth, phs_t *phs));

#define OTYPE_IS_LONG(t)  ((t)==8 || (t)==24 || (t)==94 || (t)==95)

int oci_error_err _((SV *h, OCIError *errhp, sword status, char *what, sb4 force_err));
#define oci_error(h, errhp, status, what) oci_error_err(h, errhp, status, what, 0)
char *oci_stmt_type_name _((int stmt_type));
char *oci_status_name _((sword status));
char * oci_hdtype_name _((ub4 hdtype));
int dbd_rebind_ph_lob _((SV *sth, imp_sth_t *imp_sth, phs_t *phs));

int dbd_rebind_ph_nty _((SV *sth, imp_sth_t *imp_sth, phs_t *phs));

int ora_st_execute_array _((SV *sth, imp_sth_t *imp_sth, SV *tuples,
                            SV *tuples_status, SV *columns, ub4 exe_count));


SV * ora_create_xml _((SV *dbh, char *source));

void ora_free_lob_refetch _((SV *sth, imp_sth_t *imp_sth));
void dbd_phs_avsv_complete _((phs_t *phs, I32 index, I32 debug));
void dbd_phs_sv_complete _((phs_t *phs, SV *sv, I32 debug));
int post_execute_lobs _((SV *sth, imp_sth_t *imp_sth, ub4 row_count));
ub4 ora_parse_uid _((imp_dbh_t *imp_dbh, char **uidp, char **pwdp));
char *ora_sql_error _((imp_sth_t *imp_sth, char *msg));
char *ora_env_var(char *name, char *buf, unsigned long size);

#ifdef __CYGWIN32__
void ora_cygwin_set_env(char *name, char *value);
#endif /* __CYGWIN32__ */

sb4 dbd_phs_in _((dvoid *octxp, OCIBind *bindp, ub4 iter, ub4 index,
              dvoid **bufpp, ub4 *alenp, ub1 *piecep, dvoid **indpp));
sb4 dbd_phs_out _((dvoid *octxp, OCIBind *bindp, ub4 iter, ub4 index,
             dvoid **bufpp, ub4 **alenpp, ub1 *piecep,
             dvoid **indpp, ub2 **rcodepp));
int dbd_rebind_ph_rset _((SV *sth, imp_sth_t *imp_sth, phs_t *phs));

void * oci_db_handle(imp_dbh_t *imp_dbh, int handle_type, int flags);
void * oci_st_handle(imp_sth_t *imp_sth, int handle_type, int flags);
void fb_ary_free(fb_ary_t *fb_ary);

#include "ocitrace.h"



/* These defines avoid name clashes for multiple statically linked DBD's	*/

#define dbd_init		    ora_init
#define dbd_db_login		ora_db_login
#define dbd_db_login6		ora_db_login6
#define dbd_db_do		    ora_db_do
#define dbd_db_commit		ora_db_commit
#define dbd_db_rollback		ora_db_rollback
#define dbd_db_cancel		ora_db_cancel
#define dbd_db_disconnect	ora_db_disconnect
#define dbd_db_destroy		ora_db_destroy
#define dbd_db_STORE_attrib	ora_db_STORE_attrib
#define dbd_db_FETCH_attrib	ora_db_FETCH_attrib
#define dbd_st_prepare		ora_st_prepare
#define dbd_st_rows		    ora_st_rows
#define dbd_st_cancel		ora_st_cancel
#define dbd_st_execute		ora_st_execute
#define dbd_st_fetch		ora_st_fetch
#define dbd_st_finish		ora_st_finish
#define dbd_st_destroy		ora_st_destroy
#define dbd_st_blob_read	ora_st_blob_read
#define dbd_st_STORE_attrib	ora_st_STORE_attrib
#define dbd_st_FETCH_attrib	ora_st_FETCH_attrib
#define dbd_describe		ora_describe
#define dbd_bind_ph		    ora_bind_ph

/* end */

