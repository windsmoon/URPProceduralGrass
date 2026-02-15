using System;
using UnityEngine;

namespace URPProceduralGrass
{
    public class Grass : MonoBehaviour
    {
        #region fields
        [SerializeField]
        private ComputeShader _computeShader;
        [SerializeField]
        private float _grassSpacing = 0.1f;
        [SerializeField]
        private int _resolution = 100;

        private ComputeBuffer _grassBladesBuffer;

        private static readonly int
            s_grassBladesBufferId = Shader.PropertyToID("_GrassBlades"),
            s_resolutionId = Shader.PropertyToID("_Resolution"),
            s_grassSpacingId = Shader.PropertyToID("_GrassSpacing");

        #endregion

        #region unity methods
        private void Awake()
        {
            Init();
        }

        private void Update()
        {
            UpdateGpuBuffer();
        }
        
        private void OnDestroy()
        {
            DisposeBuffers();
        }

        #endregion

        #region methods
        private void Init()
        {
            InitComputerBuffer();
        }
        
        private void InitComputerBuffer()
        {
            _grassBladesBuffer = new ComputeBuffer(_resolution * _resolution, sizeof(float) * 3, ComputeBufferType.Append);
            _grassBladesBuffer.SetCounterValue(0);
        }

        private void DisposeBuffers()
        {
            DisposeComputeBuffer();
        }

        private void DisposeComputeBuffer()
        {
            if (_grassBladesBuffer != null)
            {
                _grassBladesBuffer.Dispose();
                _grassBladesBuffer = null;
            }
        }

        private void UpdateGpuBuffer()
        {
            _grassBladesBuffer.SetCounterValue(0);
            SetComputerShaderParameters();
            int threadGroupX = Mathf.CeilToInt(_resolution / 8f);
            int threadGroupY = Mathf.CeilToInt(_resolution / 8f);
            _computeShader.Dispatch(0, threadGroupX, threadGroupY, 1);
        }

        private void SetComputerShaderParameters()
        {
            _computeShader.SetInt(s_resolutionId, _resolution);
            _computeShader.SetBuffer(0, s_grassBladesBufferId, _grassBladesBuffer);
            _computeShader.SetFloat(s_grassSpacingId, _grassSpacing);
        }
        #endregion
    }
}