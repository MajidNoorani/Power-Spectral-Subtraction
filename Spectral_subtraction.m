close all
clear all

mkdir Voices_spectral
mkdir Voices_spectral speech1 
mkdir Voices_spectral speech2

segSNR1 = cell(3,1);
segSNR2 = cell(3,1);
for speech = 1:2
    for noise_type = 1:3
        if speech == 1
            [statement,fs] = audioread('speech1.wav');
            speech_name = 'speech1';
        elseif speech == 2
            [statement,fs] = audioread('speech2.wav');
            speech_name = 'speech2';
        end
        if noise_type == 1
            [noise,fs] = audioread('White_short.wav');
            noise_name = 'white';
        elseif noise_type == 2
            [noise,fs] = audioread('Babble_short.wav');
            noise_name = 'babble';
        elseif noise_type == 3
            [noise,fs] = audioread('Volvo_short.wav');
            noise_name = 'volvo';
        end
          statement = statement *1/10;
          noise = noise*1/10;
    
        statement_size=size(statement);
        noise=noise(1:statement_size(1,1));

        %% signal making with different SNRs :-5 0 5 10

        [snr,ratio]=SNR(statement,noise);
        if snr~=0
            noise0=noise*sqrt(ratio);
        end

        %[snr1,ratio1]=SNR(statement,noise_min5);
        audio = cell(4,1);
        audio{1,1} = statement + noise0 *sqrt(sqrt(10));
        audio{2,1} = statement + noise0;  % noisy audio with snr = 0
        audio{3,1} = statement + noise0 * 1/sqrt(sqrt(10));
        audio{4,1} = statement + noise0 * 1/sqrt(10);



        %% framming
        % [frames] = framming(statement,fs);
        frames = cell(4,1);
        [frames{1,1}] = framming(audio{1,1},fs);
        [frames{2,1}] = framming(audio{2,1},fs);
        [frames{3,1}] = framming(audio{3,1},fs);
        [frames{4,1}] = framming(audio{4,1},fs);

        %% Hanning
        for i = 1: size(frames)
            [frames{i}]= Hanning(frames{i},size(frames{i},1));
        end


        %% FFT

        for i= 1:size(frames,1)
        [frames_FFT{i,1},frq] = FFT_of_Frames(frames{i,1},fs);
        %frames_FFT{i,1} = frames_FFT{i,1}(:,1:201);
        end


        %% noise esimation

        [noise_estim,label] = Direct_estim(frames_FFT);
        
        
        %% power spectral subtarction
        beta = 0.01;
        signal = cell(size(frames));
        for i = 1:size(frames,1)
            for frame = 1: size(frames{i},1)
                signal{i}(frame,:) = sqrt(frames_FFT{i}(frame,:).^2 - noise_estim{i}(frame,:).^2 );
                for k = 1:size(frames{i},2)
                    if signal{i}(frame,k) < beta*frames_FFT{i}(frame,k)
                        signal{i}(frame,k) = beta*frames_FFT{i}(frame,k);
                    end
                end
            end
        end
        
        [final_signal] = Reconstruction(signal,frames);
        
        
        filename = 'min5db.wav';
        audiowrite(filename,final_signal{4},16000);
        address=strcat('Voices_spectral\',speech_name,'\');

        


        figure
        subplot(5,2,2)
        plot(statement)
        title(strcat('clean-',speech_name))
        subplot(5,2,1)
        plot(noise)
        title(noise_name)

        for i = 1: size(audio,1)
            
            subplot(5,2,2*i+1)
            plot(audio{i})
            if i == 1
                name1 = '-5db Noisy';
                audiowrite(strcat(address,'minus5db_noisy_',noise_name,'.wav'),audio{i}*5,16000);
            elseif i == 2
                name1 = '0db Noisy';
                audiowrite(strcat(address,'0db_noisy_',noise_name,'.wav'),audio{i}*5,16000);
            elseif i == 3
                name1 = '5db Noisy';
                audiowrite(strcat(address,'5db_noisy_',noise_name,'.wav'),audio{i}*5,16000);
            else 
                name1 = '10db Noisy';
                audiowrite(strcat(address,'10db_noisy_',noise_name,'.wav'),audio{i}*5,16000);
            end
            title(name1)


            subplot(5,2,2*i+2)
            plot(1:size(final_signal{i},2),final_signal{i})
            if i == 1
                name2 = '-5db Enhanced';
                audiowrite(strcat(address,'minus5db_enhanced_',noise_name,'.wav'),final_signal{i}*5,16000);
            elseif i == 2
                name2 = '0db Enhanced';
                audiowrite(strcat(address,'0db_enhanced_',noise_name,'.wav'),final_signal{i}*5,16000);
            elseif i == 3
                name2 = '5db Enhanced';
                audiowrite(strcat(address,'5db_enhanced_',noise_name,'.wav'),final_signal{i}*5,16000);
            else 
                name2 = '10db Enhanced';
                audiowrite(strcat(address,'10db_enhanced_',noise_name,'.wav'),final_signal{i}*5,16000);
            end
            title(name2)
        
       end
        if speech == 1
            
            [segSNR1{noise_type}] = Evaluation(statement(1:max(size(final_signal{i}))),final_signal);
            
        else
            [segSNR2{noise_type}] = Evaluation(statement(1:max(size(final_signal{i}))),final_signal);
        end

    end
end

