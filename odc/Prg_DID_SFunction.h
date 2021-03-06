/*
 * Prg_DID_SFunction.h -- 
 *   - double integrator example accessing discrete-time Simulink S-function
 *     (derived from double integrator example accessing Docp interface)
 *
 * rf, 05/05/01
 */

#ifndef Prg_DID_SFunction_H
#define Prg_DID_SFunction_H

#include <Omu_Program.h>

#define HXI_INLINE_S_FUNCTION 1
#define HXI_REAL_T adouble
#include "sfun_did.c"

//--------------------------------------------------------------------------
class Prg_DID_SFunction: public Omu_Program {

 protected:

  SimStruct *_SS;

  void setup_stages(IVECP ks, VECP ts);

  void setup(int k,
	     Omu_Vector &x, Omu_Vector &u, Omu_Vector &c);

  void update(int kk,
	      const adoublev &x, const adoublev &u,
	      adoublev &f, adouble &f0, adoublev &c);

  int _nx;	// number of states
  int _nu;	// number of control parameters
  int _mdl_ny;	// number of model outputs
  double _dt; 	// sample time
  bool _with_cns;// treat overshoot with additional constraint

  mxArray *_mx_dt; // dt parameter for model

 public:

  Prg_DID_SFunction();
  ~Prg_DID_SFunction();

  const char *name() {return "DID_SFunction";}
};  

#endif

