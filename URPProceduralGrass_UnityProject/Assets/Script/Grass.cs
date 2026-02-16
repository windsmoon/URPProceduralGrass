using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace URPProceduralGrass
{
    public class Grass : MonoBehaviour
    {
        #region fields
        private const int ArgsStride = sizeof(int) * 4;

        [SerializeField]
        private ComputeShader _computeShader;
        [SerializeField] 
        private Material _material;
        [SerializeField]
        private Camera _camera;
        [SerializeField]
        private float _grassSpacing = 0.1f;
        [SerializeField]
        private int _resolution = 100;
        [SerializeField, Range(0, 2)]
        private float _positionJitterStrength;

        private ComputeBuffer _grassBladesBuffer;
        private ComputeBuffer _meshTrianglesBuffer;
        private ComputeBuffer _meshPositionsBuffer;
        private ComputeBuffer _meshColorsBuffer;
        private ComputeBuffer _meshUvsBuffer;
        private ComputeBuffer _argsBuffer;
        private Mesh _clonedMesh;
        private Bounds _bounds;

        private static readonly int
            s_grassBladesBufferId = Shader.PropertyToID("_GrassBlades"),
            s_resolutionId = Shader.PropertyToID("_Resolution"),
            s_grassSpacingId = Shader.PropertyToID("_GrassSpacing"),
            s_positionJitterStrengthId = Shader.PropertyToID("_PositionJitterStrength");

        #endregion

        #region unity methods
        private void Awake()
        {
            Init();
            _bounds = new Bounds(Vector3.zero, Vector3.one * 10000f);
        }

        private void Update()
        {
            UpdateGpuBuffer();
        }

        private void LateUpdate()
        {
            RenderGrass();
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
            SetMeshBuffers();
        }
        
        private void InitComputerBuffer()
        {
            _grassBladesBuffer = new ComputeBuffer(_resolution * _resolution, sizeof(float) * 3, ComputeBufferType.Append);
            _grassBladesBuffer.SetCounterValue(0);
            
            _argsBuffer = new ComputeBuffer(1, ArgsStride, ComputeBufferType.IndirectArguments);
        }

        private void SetMeshBuffers()
        {
            _clonedMesh = GrassMesh.CreateHighLODMesh();
            _clonedMesh.name = "Grass Instance Mesh";
            
            CreateComputeBuffersFroMesh();
            _argsBuffer.SetData(new int[] {_meshTrianglesBuffer.count, 0, 0, 0});
        }

        private ComputeBuffer CreateBuffer<T>(T[] data, int stride) where T : struct
        {
            ComputeBuffer buffer = new ComputeBuffer(data.Length, stride);
            buffer.SetData(data);
            return buffer;
        }
        
        private void CreateComputeBuffersFroMesh()
        {
            int[] triangles = _clonedMesh.triangles;
            Vector3[] vertices = _clonedMesh.vertices;
            Color[] colors = _clonedMesh.colors;
            Vector2[] uvs = _clonedMesh.uv;

            _meshTrianglesBuffer = CreateBuffer<int>(triangles, sizeof(int));
            _meshPositionsBuffer = CreateBuffer<Vector3>(vertices, sizeof(float) * 3);
            _meshColorsBuffer = CreateBuffer<Color>(colors, sizeof(float) * 4);
            _meshUvsBuffer = CreateBuffer<Vector2>(uvs, sizeof(float) * 2);
        }

        private void RenderGrass()
        {
            ComputeBuffer.CopyCount(_grassBladesBuffer, _argsBuffer, sizeof(int));
            Graphics.DrawProceduralIndirect(_material, _bounds, MeshTopology.Triangles, _argsBuffer,
                0, _camera, null, ShadowCastingMode.Off, true, gameObject.layer);
        }
        
        private void DisposeBuffers()
        {
            DisposeComputeBuffer(_grassBladesBuffer);
            DisposeComputeBuffer(_meshTrianglesBuffer);
            DisposeComputeBuffer(_meshPositionsBuffer);
            DisposeComputeBuffer(_meshColorsBuffer);
            DisposeComputeBuffer(_meshUvsBuffer);
            DisposeComputeBuffer(_argsBuffer);
        }

        private void DisposeComputeBuffer(ComputeBuffer buffer)
        {
            if (buffer != null)
            {
                buffer.Dispose();
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
            _computeShader.SetFloat(s_positionJitterStrengthId, _positionJitterStrength);
        }
        #endregion
    }
}