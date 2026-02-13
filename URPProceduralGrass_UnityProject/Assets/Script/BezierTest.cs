#if UNITY_EDITOR
using UnityEngine;

namespace URPProceduralGrass
{
    public class BezierTest : MonoBehaviour
    {
        #region fields
        [SerializeField]
        private Transform _p0;
        [SerializeField]
        private Transform _p1;
        [SerializeField]
        private Transform _p2;
        [SerializeField]
        private Transform _p3;
        [SerializeField]
        private int segmentCount = 20;
        [SerializeField]
        private float _gizmoSize = 0.1f;
        [SerializeField]
        private Color curveColor = Color.green;
        [SerializeField]
        private Color controlPointColor = Color.yellow;
        #endregion

        #region unity methods
        private void OnDrawGizmos()
        {
            if (_p0 == null || _p1 == null || _p2 == null || _p3 == null)
            {
                return;
            }

            Gizmos.color = controlPointColor;
            Gizmos.DrawSphere(_p0.position, _gizmoSize);
            Gizmos.DrawSphere(_p1.position, _gizmoSize);
            Gizmos.DrawSphere(_p2.position, _gizmoSize);
            Gizmos.DrawSphere(_p3.position, _gizmoSize);

            Gizmos.color = Color.gray;
            Gizmos.DrawLine(_p0.position, _p1.position);
            Gizmos.DrawLine(_p1.position, _p2.position);
            Gizmos.DrawLine(_p2.position, _p3.position);

            Gizmos.color = curveColor;
            Vector3 prviousPoint = _p0.position;
            for (int i = 1; i <= segmentCount; i++)
            {
                float t = (float)i / segmentCount;
                Vector3 currentPoint = CubicBezier(_p0.position, _p1.position, _p2.position, _p3.position, t);
                Gizmos.DrawLine(prviousPoint, currentPoint);
                prviousPoint = currentPoint;
            }

        }
        #endregion
        
        #region methods
        public static Vector3 CubicBezier(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            float omt = 1f - t;
            float omt2 = omt * omt;
            float t2 = t * t;
            return p0 * (omt * omt2) +
                   p1 * (3f * omt2 * t) +
                   p2 * (3f * omt * t2) +
                   p3 * (t * t2);
        }
        #endregion
    }
}
#endif