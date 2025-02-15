; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -simplifycfg -simplifycfg-require-and-preserve-domtree=1  -S | FileCheck %s

define void @test1(i1 %C, i1* %BP) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = xor i1 [[C:%.*]], true
; CHECK-NEXT:    call void @llvm.assume(i1 [[TMP0]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %C, label %T, label %F
T:
  store i1 %C, i1* %BP
  unreachable
F:
  ret void
}

define void @test2() personality i32 (...)* @__gxx_personality_v0 {
; CHECK-LABEL: @test2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    call void @test2()
; CHECK-NEXT:    ret void
;
entry:
  invoke void @test2( )
  to label %N unwind label %U
U:
  %res = landingpad { i8* }
  cleanup
  unreachable
N:
  ret void
}

declare i32 @__gxx_personality_v0(...)

define i32 @test3(i32 %v) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[COND:%.*]] = icmp eq i32 [[V:%.*]], 2
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[COND]], i32 2, i32 1
; CHECK-NEXT:    ret i32 [[SPEC_SELECT]]
;
entry:
  switch i32 %v, label %default [
  i32 1, label %U
  i32 2, label %T
  ]
default:
  ret i32 1
U:
  unreachable
T:
  ret i32 2
}


;; We can either convert the following control-flow to a select or remove the
;; unreachable control flow because of the undef store of null. Make sure we do
;; the latter.

define void @test5(i1 %cond, i8* %ptr) {
; CHECK-LABEL: @test5(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PTR_2:%.*]] = select i1 [[COND:%.*]], i8* null, i8* [[PTR:%.*]]
; CHECK-NEXT:    store i8 2, i8* [[PTR_2]], align 8
; CHECK-NEXT:    ret void
;
entry:
  br i1 %cond, label %bb1, label %bb3

bb3:
  br label %bb2

bb1:
  br label %bb2

bb2:
  %ptr.2 = phi i8* [ %ptr, %bb3 ], [ null, %bb1 ]
  store i8 2, i8* %ptr.2, align 8
  ret void
}

declare void @llvm.assume(i1)
declare i1 @llvm.type.test(i8*, metadata) nounwind readnone

;; Same as the above test but make sure the unreachable control flow is still
;; removed in the presence of a type test / assume sequence.

define void @test5_type_test_assume(i1 %cond, i8* %ptr, [3 x i8*]* %vtable) {
; CHECK-LABEL: @test5_type_test_assume(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PTR_2:%.*]] = select i1 [[COND:%.*]], i8* null, i8* [[PTR:%.*]]
; CHECK-NEXT:    [[VTABLEI8:%.*]] = bitcast [3 x i8*]* [[VTABLE:%.*]] to i8*
; CHECK-NEXT:    [[P:%.*]] = call i1 @llvm.type.test(i8* [[VTABLEI8]], metadata !"foo")
; CHECK-NEXT:    tail call void @llvm.assume(i1 [[P]])
; CHECK-NEXT:    store i8 2, i8* [[PTR_2]], align 8
; CHECK-NEXT:    ret void
;
entry:
  br i1 %cond, label %bb1, label %bb3

bb3:
  br label %bb2

bb1:
  br label %bb2

bb2:
  %ptr.2 = phi i8* [ %ptr, %bb3 ], [ null, %bb1 ]
  %vtablei8 = bitcast [3 x i8*]* %vtable to i8*
  %p = call i1 @llvm.type.test(i8* %vtablei8, metadata !"foo")
  tail call void @llvm.assume(i1 %p)
  store i8 2, i8* %ptr.2, align 8
  ret void
}

define void @test5_no_null_opt(i1 %cond, i8* %ptr) #0 {
; CHECK-LABEL: @test5_no_null_opt(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[DOTPTR:%.*]] = select i1 [[COND:%.*]], i8* null, i8* [[PTR:%.*]]
; CHECK-NEXT:    store i8 2, i8* [[DOTPTR]], align 8
; CHECK-NEXT:    ret void
;
entry:
  br i1 %cond, label %bb1, label %bb3

bb3:
  br label %bb2

bb1:
  br label %bb2

bb2:
  %ptr.2 = phi i8* [ %ptr, %bb3 ], [ null, %bb1 ]
  store i8 2, i8* %ptr.2, align 8
  ret void
}

define void @test6(i1 %cond, i8* %ptr) {
; CHECK-LABEL: @test6(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PTR_2:%.*]] = select i1 [[COND:%.*]], i8* null, i8* [[PTR:%.*]]
; CHECK-NEXT:    store i8 2, i8* [[PTR_2]], align 8
; CHECK-NEXT:    ret void
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  br label %bb2

bb2:
  %ptr.2 = phi i8* [ %ptr, %entry ], [ null, %bb1 ]
  store i8 2, i8* %ptr.2, align 8
  ret void
}

define void @test6_no_null_opt(i1 %cond, i8* %ptr) #0 {
; CHECK-LABEL: @test6_no_null_opt(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[COND:%.*]], i8* null, i8* [[PTR:%.*]]
; CHECK-NEXT:    store i8 2, i8* [[SPEC_SELECT]], align 8
; CHECK-NEXT:    ret void
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  br label %bb2

bb2:
  %ptr.2 = phi i8* [ %ptr, %entry ], [ null, %bb1 ]
  store i8 2, i8* %ptr.2, align 8
  ret void
}


define i32 @test7(i1 %X) {
; CHECK-LABEL: @test7(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = xor i1 [[X:%.*]], true
; CHECK-NEXT:    call void @llvm.assume(i1 [[TMP0]])
; CHECK-NEXT:    ret i32 0
;
entry:
  br i1 %X, label %if, label %else

if:
  call void undef()
  br label %else

else:
  %phi = phi i32 [ 0, %entry ], [ 1, %if ]
  ret i32 %phi
}

define void @test8(i1 %X, void ()* %Y) {
; CHECK-LABEL: @test8(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], void ()* null, void ()* [[Y:%.*]]
; CHECK-NEXT:    call void [[PHI]]()
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi void ()* [ %Y, %entry ], [ null, %if ]
  call void %phi()
  ret void
}

define void @test8_no_null_opt(i1 %X, void ()* %Y) #0 {
; CHECK-LABEL: @test8_no_null_opt(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], void ()* null, void ()* [[Y:%.*]]
; CHECK-NEXT:    call void [[SPEC_SELECT]]()
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi void ()* [ %Y, %entry ], [ null, %if ]
  call void %phi()
  ret void
}

declare i8* @fn_nonnull_noundef_arg(i8* nonnull noundef %p)
declare i8* @fn_nonnull_deref_arg(i8* nonnull dereferenceable(4) %p)
declare i8* @fn_nonnull_deref_or_null_arg(i8* nonnull dereferenceable_or_null(4) %p)
declare i8* @fn_nonnull_arg(i8* nonnull %p)
declare i8* @fn_noundef_arg(i8* noundef %p)

define void @test9(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[PHI]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_noundef_arg(i8* %phi)
  ret void
}

; Optimizing this code should produce assume.
define void @test9_deref(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_deref(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_deref_arg(i8* [[PHI]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_deref_arg(i8* %phi)
  ret void
}

; Optimizing this code should produce assume.
define void @test9_deref_or_null(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_deref_or_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_deref_or_null_arg(i8* [[PHI]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_deref_or_null_arg(i8* %phi)
  ret void
}

define void @test9_undef(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_undef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_noundef_arg(i8* [[Y:%.*]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ undef, %if ]
  call i8* @fn_noundef_arg(i8* %phi)
  ret void
}

define void @test9_undef_null_defined(i1 %X, i8* %Y) #0 {
; CHECK-LABEL: @test9_undef_null_defined(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_noundef_arg(i8* [[Y:%.*]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ undef, %if ]
  call i8* @fn_noundef_arg(i8* %phi)
  ret void
}

define void @test9_null_callsite(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_null_callsite(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_arg(i8* noundef nonnull [[PHI]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_arg(i8* nonnull noundef %phi)
  ret void
}

define void @test9_gep_mismatch(i1 %X, i8* %Y,  i8* %P) {
; CHECK-LABEL: @test9_gep_mismatch(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8* [[P:%.*]], i64 0
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr inbounds i8, i8* %P, i64 0
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}

define void @test9_gep_zero(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_gep_zero(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8* [[PHI]], i64 0
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr inbounds i8, i8* %phi, i64 0
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}

define void @test9_gep_bitcast(i1 %X, i32* %Y) {
; CHECK-LABEL: @test9_gep_bitcast(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[PHI:%.*]] = select i1 [[X:%.*]], i32* null, i32* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i32, i32* [[PHI]], i64 0
; CHECK-NEXT:    [[BC:%.*]] = bitcast i32* [[GEP]] to i8*
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[BC]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i32* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr inbounds i32, i32* %phi, i64 0
  %bc = bitcast i32* %gep to i8*
  call i8* @fn_nonnull_noundef_arg(i8* %bc)
  ret void
}

define void @test9_gep_nonzero(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_gep_nonzero(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i8, i8* [[SPEC_SELECT]], i64 12
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr i8, i8* %phi, i64 12
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}

define void @test9_gep_inbounds_nonzero(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_gep_inbounds_nonzero(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8* [[SPEC_SELECT]], i64 12
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr inbounds i8, i8* %phi, i64 12
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}


define void @test9_gep_inbouds_unknown_null(i1 %X, i8* %Y, i64 %I) {
; CHECK-LABEL: @test9_gep_inbouds_unknown_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds i8, i8* [[SPEC_SELECT]], i64 [[I:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr inbounds i8, i8* %phi, i64 %I
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}

define void @test9_gep_unknown_null(i1 %X, i8* %Y, i64 %I) {
; CHECK-LABEL: @test9_gep_unknown_null(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i8, i8* [[SPEC_SELECT]], i64 [[I:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  %gep = getelementptr i8, i8* %phi, i64 %I
  call i8* @fn_nonnull_noundef_arg(i8* %gep)
  ret void
}

define void @test9_gep_unknown_undef(i1 %X, i8* %Y, i64 %I) {
; CHECK-LABEL: @test9_gep_unknown_undef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i8, i8* [[Y:%.*]], i64 [[I:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_noundef_arg(i8* [[GEP]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ undef, %if ]
  %gep = getelementptr i8, i8* %phi, i64 %I
  call i8* @fn_noundef_arg(i8* %gep)
  ret void
}

define void @test9_missing_noundef(i1 %X, i8* %Y) {
; CHECK-LABEL: @test9_missing_noundef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_arg(i8* [[SPEC_SELECT]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_arg(i8* %phi)
  ret void
}

define void @test9_null_defined(i1 %X, i8* %Y) #0 {
; CHECK-LABEL: @test9_null_defined(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = select i1 [[X:%.*]], i8* null, i8* [[Y:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = call i8* @fn_nonnull_noundef_arg(i8* [[SPEC_SELECT]])
; CHECK-NEXT:    ret void
;
entry:
  br i1 %X, label %if, label %else

if:
  br label %else

else:
  %phi = phi i8* [ %Y, %entry ], [ null, %if ]
  call i8* @fn_nonnull_noundef_arg(i8* %phi)
  ret void
}



attributes #0 = { null_pointer_is_valid }
