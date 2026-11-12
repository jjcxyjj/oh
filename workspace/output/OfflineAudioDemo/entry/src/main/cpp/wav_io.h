// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <string>

inline void Require(bool ok, const std::string& message) {
    if (!ok) throw std::runtime_error(message);
}
inline uint32_t Get32(const unsigned char* p) {
    return uint32_t(p[0]) | uint32_t(p[1])<<8 | uint32_t(p[2])<<16 | uint32_t(p[3])<<24;
}
inline uint16_t Get16(const unsigned char* p) { return uint16_t(p[0]) | uint16_t(p[1])<<8; }
inline void Put32(unsigned char* p, uint32_t n) { for (int i=0;i<4;++i) p[i]=(n>>(8*i))&255; }

// 只接受明确约定的 48kHz / stereo / PCM16。支持标准 WAV 块和裸 PCM。
// WAV 会跳过头部；不能把 RIFF 头当成音频喂给算法。
class PcmReader {
    FILE* file_ = nullptr;
    long remaining_ = 0;
    double gain_;
public:
    explicit PcmReader(const std::string& path, double gain=1.0): gain_(gain) {
        file_=fopen(path.c_str(),"rb");
        try {
            Require(file_,"无法打开输入: "+path);
            Require(fseek(file_,0,SEEK_END)==0,"输入不可定位");
            long total=ftell(file_); rewind(file_);
            Require(total>0,"输入为空");
            unsigned char h[12]{};
            size_t n=fread(h,1,12,file_);
            long dataStart=0, dataSize=total;
            if (n==12 && !memcmp(h,"RIFF",4) && !memcmp(h+8,"WAVE",4)) {
                bool fmt=false, data=false;
                while (ftell(file_)+8<=total) {
                    unsigned char chunk[8]; Require(fread(chunk,1,8,file_)==8,"WAV 块头损坏");
                    uint32_t size=Get32(chunk+4); long start=ftell(file_);
                    Require(static_cast<uint64_t>(start)+size<=static_cast<uint64_t>(total),"WAV 块越界");
                    if (!memcmp(chunk,"fmt ",4)) {
                        unsigned char f[16]; Require(size>=16 && fread(f,1,16,file_)==16,"WAV fmt 损坏");
                        Require(Get16(f)==1 && Get16(f+2)==2 && Get32(f+4)==48000 &&
                            Get16(f+12)==4 && Get16(f+14)==16,"需要 48kHz 双声道 PCM16 WAV");
                        fmt=true;
                    } else if (!memcmp(chunk,"data",4)) { dataStart=start; dataSize=size; data=true; }
                    Require(fseek(file_,start+size+(size&1),SEEK_SET)==0,"WAV 定位失败");
                }
                Require(fmt && data,"WAV 缺少 fmt 或 data 块");
            } else {
                Require(path.size()>=4 && path.substr(path.size()-4)==".pcm","仅支持 PCM16 WAV 或 .pcm 裸音频");
            }
            Require(dataSize>0 && dataSize%4==0 && dataSize<=192000L*120,"输入长度需要在 0–120 秒内，且按双声道帧对齐");
            Require(fseek(file_,dataStart,SEEK_SET)==0,"PCM 定位失败"); remaining_=dataSize;
        } catch (...) { if(file_) fclose(file_); file_=nullptr; throw; }
    }
    ~PcmReader() { if(file_) fclose(file_); }
    PcmReader(const PcmReader&)=delete;
    int Read(void* buffer, int capacity, bool* finished) {
        if (!buffer || !finished || capacity<=0 || capacity%4) return -1;
        size_t requested=std::min<long>(remaining_,capacity);
        size_t count=fread(buffer,1,requested,file_);
        if (count!=requested || ferror(file_)) return -1;
        remaining_-=count; *finished=remaining_==0;
        auto p=static_cast<unsigned char*>(buffer);
        for(size_t i=0;i<count;i+=2) {
            int sample=static_cast<int16_t>(Get16(p+i));
            int scaled=std::clamp(static_cast<int>(std::lround(sample*gain_)),-32768,32767);
            p[i]=scaled&255; p[i+1]=(scaled>>8)&255;
        }
        return static_cast<int>(count);
    }
};

// 每个任务使用唯一输出目录前缀；先写 .part，结束后再发布 WAV。
class WavWriter {
    FILE* file_=nullptr;
    std::string path_, temp_;
    uint32_t bytes_=0;
public:
    explicit WavWriter(const std::string& path):path_(path),temp_(path+".part") {
        file_=fopen(temp_.c_str(),"wb"); Require(file_,"无法创建输出 WAV");
        unsigned char h[44]{};
        if(fwrite(h,1,44,file_)!=44) { fclose(file_);file_=nullptr;remove(temp_.c_str());throw std::runtime_error("WAV 头写入失败"); }
    }
    ~WavWriter() { if(file_) fclose(file_);remove(temp_.c_str()); }
    void Append(const void* buffer,int count) {
        Require(count>=0 && count%4==0,"输出未按 PCM 帧对齐");
        Require(bytes_+count<=192000U*180,"输出超过 180 秒保护上限");
        Require(fwrite(buffer,1,count,file_)==static_cast<size_t>(count),"WAV 数据写入失败");bytes_+=count;
    }
    void Commit() {
        Require(bytes_>0,"算法输出为空");
        std::array<unsigned char,44> h{};
        memcpy(h.data(),"RIFF",4);Put32(h.data()+4,bytes_+36);memcpy(h.data()+8,"WAVEfmt ",8);
        Put32(h.data()+16,16);h[20]=1;h[22]=2;Put32(h.data()+24,48000);Put32(h.data()+28,192000);
        h[32]=4;h[34]=16;memcpy(h.data()+36,"data",4);Put32(h.data()+40,bytes_);
        Require(fseek(file_,0,SEEK_SET)==0 && fwrite(h.data(),1,44,file_)==44,"WAV 头回填失败");
        int status=fclose(file_);file_=nullptr;Require(status==0,"WAV 关闭失败");
        Require(rename(temp_.c_str(),path_.c_str())==0,"WAV 提交失败");
    }
};
