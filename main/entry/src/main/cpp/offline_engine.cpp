// SPDX-License-Identifier: Apache-2.0
// ArkTS → N-API → 后台线程 → audio_pipeline.cpp。此文件只负责语言桥接。
#include <napi/native_api.h>
#include "audio_pipeline.h"
#include <memory>

struct AsyncJob { RenderJob audio; napi_async_work work{}; napi_deferred deferred{}; };
static napi_value Text(napi_env env,const std::string& text) {
    napi_value v;napi_create_string_utf8(env,text.c_str(),text.size(),&v);return v;
}
static void Execute(napi_env,void* data) { RunAudioJob(static_cast<AsyncJob*>(data)->audio); }
static void Complete(napi_env env,napi_status status,void* data) {
    std::unique_ptr<AsyncJob> j(static_cast<AsyncJob*>(data));auto& a=j->audio;
    if(status!=napi_ok && a.error.empty()) a.error="后台任务被取消";
    if(!a.error.empty()) {
        napi_value error;napi_create_error(env,nullptr,Text(env,a.error),&error);napi_reject_deferred(env,j->deferred,error);
    } else {
        napi_value result,paths,labels,elapsed;
        napi_create_object(env,&result);napi_create_array(env,&paths);napi_create_array(env,&labels);
        for(size_t i=0;i<a.paths.size();++i) {
            napi_set_element(env,paths,i,Text(env,a.paths[i]));napi_set_element(env,labels,i,Text(env,a.labels[i]));
        }
        napi_create_double(env,a.elapsedMs,&elapsed);
        napi_set_named_property(env,result,"paths",paths);napi_set_named_property(env,result,"labels",labels);
        napi_set_named_property(env,result,"elapsedMs",elapsed);napi_resolve_deferred(env,j->deferred,result);
    }
    napi_delete_async_work(env,j->work);
}
static bool Path(napi_env env,napi_value value,std::string& out) {
    char buffer[4096];size_t n=0;
    if(napi_get_value_string_utf8(env,value,buffer,sizeof(buffer),&n)!=napi_ok || n>=4095) return false;
    out.assign(buffer,n);return out.find('\0')==std::string::npos;
}
// 页面按钮会调用 run；不是自动加载历史 WAV。
static napi_value Run(napi_env env,napi_callback_info info) {
    size_t argc=7;napi_value args[7];napi_get_cb_info(env,info,&argc,args,nullptr,nullptr);
    auto j=std::make_unique<AsyncJob>();auto& a=j->audio;
    if(argc!=7 || !Path(env,args[0],a.inputA) || !Path(env,args[1],a.inputB) || !Path(env,args[2],a.prefix) ||
       napi_get_value_int32(env,args[3],&a.mode)!=napi_ok || napi_get_value_int32(env,args[4],&a.preset)!=napi_ok ||
       napi_get_value_double(env,args[5],&a.gainA)!=napi_ok || napi_get_value_double(env,args[6],&a.gainB)!=napi_ok ||
       a.inputA.empty() || a.prefix.empty()) {
        napi_throw_type_error(env,nullptr,"run(inputA,inputB,outputPrefix,mode,preset,gainA,gainB)");return nullptr;
    }
    napi_value promise,name=Text(env,"AudioSuiteOfflineJob");
    if(napi_create_promise(env,&j->deferred,&promise)!=napi_ok) return nullptr;
    auto status=napi_create_async_work(env,nullptr,name,Execute,Complete,j.get(),&j->work);
    if(status==napi_ok) status=napi_queue_async_work(env,j->work);
    if(status!=napi_ok) {
        if(j->work) napi_delete_async_work(env,j->work);
        napi_value error;napi_create_error(env,nullptr,Text(env,"无法启动后台任务"),&error);
        napi_reject_deferred(env,j->deferred,error);return promise;
    }
    j.release();return promise;
}
static napi_value Init(napi_env env,napi_value exports) {
    napi_property_descriptor props[]={{"run",nullptr,Run,nullptr,nullptr,nullptr,napi_default,nullptr}};
    napi_define_properties(env,exports,1,props);return exports;
}
static napi_module module={1,0,nullptr,Init,"entry",nullptr,{0}};
extern "C" __attribute__((constructor)) void Register() { napi_module_register(&module); }
