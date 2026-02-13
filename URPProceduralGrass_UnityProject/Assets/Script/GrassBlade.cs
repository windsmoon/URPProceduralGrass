using System;
using UnityEngine;

namespace URPProceduralGrass
{
    public class GrassBlade : MonoBehaviour
    {
        #region fields
        [SerializeField]
        private Material _material;
        #endregion

        #region methods
        private void Start()
        {
            var clonedMesh = GrassMesh.CreateHighLODMesh();
            
            MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();
            MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
            
            meshFilter.mesh = clonedMesh;
            meshRenderer.material = _material;
        }

        private void Update()
        {
        }
        #endregion
    }
}