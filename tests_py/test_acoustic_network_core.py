from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')

def test_network_core_files_exist():
    for p in [
        'src/acoustic_network_element_admittance.m',
        'src/build_acoustic_network_from_mesh.m',
        'src/assemble_acoustic_network.m',
        'src/apply_acoustic_network_sources.m',
        'src/solve_acoustic_network_harmonic.m']:
        assert (ROOT/p).exists(), p

def test_element_helper_has_required_physical_elements():
    s=read('src/acoustic_network_element_admittance.m').lower()
    for token in ['pipe_fetm','resistance','inertance','series_rl','series_impedance','compliance','chamber']:
        assert token in s
    assert 'fetm_acoustic_admittance' in s
    assert '1i*omega*cq' in s.replace(' ','')

def test_sources_include_pressure_flow_and_thevenin():
    s=read('src/apply_acoustic_network_sources.m').lower()
    for token in ['pressure','volume_flow','thevenin_pressure']:
        assert token in s
    assert 'sourcepressure/zs' in s.replace(' ','')
    assert '1/zs' in s.replace(' ','')

def test_network_solver_uses_partitioned_pressure_solution():
    s=read('src/solve_acoustic_network_harmonic.m').replace(' ','')
    assert 'Y(free,free)' in s
    assert 'Y(free,known)' in s
    assert 'pressure_field_model' in s
    assert 'acoustic_network' in s

def test_dispatcher_exposes_acoustic_network_without_removing_legacy_modes():
    s=read('src/solve_fluid_harmonic.m').lower()
    for token in ['endpoint_constrained','fetm_impedance','acoustic_network','acoustic_bvp']:
        assert token in s
    assert 'solve_acoustic_network_harmonic' in s

def pipe_y(omega,L,rho,c,A):
    k=omega/c; zv=rho*c/A
    a=1j/(zv*np.sin(k*L)); co=np.cos(k*L)
    return a*np.array([[-co,1],[1,-co]],complex),zv

def test_matched_termination_has_traveling_wave_transfer():
    rho=850.; c=1287.; A=np.pi*.013**2/4; L=.4; w=2*np.pi*400
    Y,zv=pipe_y(w,L,rho,c,A)
    Y[1,1]+=1/zv
    p=np.zeros(2,complex); p[0]=1
    p[1]=-(Y[1,0]*p[0])/Y[1,1]
    H=p[1]/p[0]
    assert np.isclose(abs(H),1,rtol=1e-10,atol=1e-10)
    assert np.isclose(np.angle(H),-w*L/c,rtol=1e-10,atol=1e-10)

def test_thevenin_source_norton_equivalent():
    Zs=3+2j; Ps=7-1j; Zload=5+4j
    p=(Ps/Zs)/(1/Zs+1/Zload)
    assert np.allclose(p,Ps*Zload/(Zs+Zload))

def test_no_hidden_harmonic_scaling_or_hbm_dependency():
    combined='\n'.join(read(p) for p in [
        'src/acoustic_network_element_admittance.m',
        'src/build_acoustic_network_from_mesh.m',
        'src/assemble_acoustic_network.m',
        'src/apply_acoustic_network_sources.m',
        'src/solve_acoustic_network_harmonic.m'])
    low=combined.lower()
    assert 'harmonic_scale' not in low
    assert '1.62' not in low
    assert 'run_hbm' not in low
