function Zt = acoustic_termination_impedance(term,omega,Zchar,omegaRef)
%ACOUSTIC_TERMINATION_IMPEDANCE Terminal volume impedance p/Q.
%
% Supported term.type:
%   anechoic
%   normalized_constant : Z/Zchar = r + i*x, r>=0
%   normalized_rlc      : Z/Zchar = r+i*(m*w/w0-q*w0/w), r,m,q>=0
%   specific_volume_impedance : direct complex p/Q

if nargin < 4 || isempty(omegaRef) || omegaRef <= 0
    omegaRef = omega;
end
if ~isfield(term,'type') || isempty(term.type)
    type = "anechoic";
else
    type = lower(string(term.type));
end

switch type
    case "anechoic"
        Zt = Zchar;

    case "normalized_constant"
        r = getfield_default(term,'r',1.0); %#ok<GFLD>
        x = getfield_default(term,'x',0.0); %#ok<GFLD>
        if r < 0
            error('PipePulse:ActiveTermination','被动端阻抗要求 r >= 0。');
        end
        Zt = Zchar*(r + 1i*x);

    case "normalized_rlc"
        r = getfield_default(term,'r',1.0); %#ok<GFLD>
        m = getfield_default(term,'m',0.0); %#ok<GFLD>
        q = getfield_default(term,'q',0.0); %#ok<GFLD>
        if r < 0 || m < 0 || q < 0
            error('PipePulse:ActiveTermination', ...
                '被动 normalized_rlc 要求 r,m,q 均非负。');
        end
        Zt = Zchar*(r + 1i*(m*(omega/omegaRef) - q*(omegaRef/omega)));

    case "specific_volume_impedance"
        if ~isfield(term,'value') || isempty(term.value)
            error('PipePulse:TerminationValue','specific_volume_impedance 需要 term.value。');
        end
        Zt = term.value;
        requirePassive = getfield_default(term,'require_passive',true); %#ok<GFLD>
        if requirePassive && real(Zt) < 0
            error('PipePulse:ActiveTermination','被动端阻抗要求 real(Zt) >= 0。');
        end

    otherwise
        error('PipePulse:TerminationType','未知声学端阻抗类型: %s。',type);
end

if ~isfinite(abs(Zt)) || abs(Zt)==0
    error('PipePulse:TerminationValue','声学端阻抗必须为有限非零值。');
end
end

function value = getfield_default(s,name,defaultValue)
if isfield(s,name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
