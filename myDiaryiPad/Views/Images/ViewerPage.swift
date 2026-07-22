//
//  ViewerPage.swift
//  myDiary
//
//  Created by 的池秋成 on 2026/07/21.
//
//
//  ViewerPage.swift
//  myDiary
//

import SwiftUI
import UIKit

/*
 ImageViewer内の画像1ページを表示するView。

 担当する処理：
 - 画像の描画
 - ピンチジェスチャーの受け取り
 - ダブルタップジェスチャーの受け取り
 - 拡大中のパンジェスチャーの受け取り

 倍率や位置の計算・保持は
 ViewerPageStateが担当する。
 */
struct ViewerPage: View {

    let image: UIImage

    let pageWidth: CGFloat
    let pageHeight: CGFloat

    let state: ViewerPageState

    /*
     ピンチ操作中だけ使用する一時倍率。
     */
    @GestureState
    private var magnification: CGFloat = 1.0

    /*
     ドラッグ操作中だけ使用する一時移動量。
     */
    @GestureState
    private var dragTranslation: CGSize = .zero

    /*
     ピンチ操作中を含めた表示倍率。
     */
    private var effectiveZoomScale: CGFloat {
        state.effectiveZoomScale(
            magnification: magnification
        )
    }

    /*
     ドラッグ操作中を含めた表示位置。
     */
    private var effectiveOffset: CGSize {
        state.effectiveOffset(
            dragTranslation: dragTranslation,
            image: image,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
            magnification: magnification
        )
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            /*
             1倍表示時の画像領域。

             画像はこの領域内でaspect fitされ、
             scaleEffectで拡大される。
             */
            .frame(
                width: max(
                    0,
                    pageWidth
                    - state.imageMargin * 2
                ),

                height: max(
                    0,
                    pageHeight
                    - state.imageMargin * 2
                )
            )
            .scaleEffect(
                effectiveZoomScale
            )
            .offset(
                effectiveOffset
            )
            /*
             ViewerPage全体を
             タップ・ドラッグ可能にする。
             */
            .frame(
                width: pageWidth,
                height: pageHeight
            )
            .contentShape(
                Rectangle()
            )
            .clipped()
            .simultaneousGesture(
                magnifyGesture
            )
            .simultaneousGesture(
                doubleTapGesture
            )
            .simultaneousGesture(
                imagePanGesture
            )
            /*
             Toolbarから倍率が変更された場合に、
             画像位置を有効範囲内へ調整する。
             */
            .onChange(
                of: state.zoomScale
            ) {
                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    state.reconcileOffset(
                        image: image,
                        pageWidth: pageWidth,
                        pageHeight: pageHeight
                    )
                }
            }
    }

    // MARK: - Magnify

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating(
                $magnification
            ) { value, gestureState, _ in
                gestureState =
                    value.magnification
            }
            .onEnded { value in
                state.finishMagnification(
                    magnification:
                        value.magnification,

                    image: image,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight
                )
            }
    }

    // MARK: - Double tap

    private var doubleTapGesture: some Gesture {
        SpatialTapGesture(
            count: 2
        )
        .onEnded { value in
            withAnimation(
                .easeInOut(duration: 0.25)
            ) {
                state.handleDoubleTap(
                    at: value.location,
                    image: image,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight
                )
            }
        }
    }

    // MARK: - Pan

    private var imagePanGesture: some Gesture {
        DragGesture(
            minimumDistance: 3,
            coordinateSpace: .local
        )
        .updating(
            $dragTranslation
        ) { value, gestureState, _ in

            /*
             1倍表示中は画像内パンを行わない。

             親Viewの左右ページ送りへ
             ドラッグ操作を渡す。
             */
            guard state.zoomScale > 1.01 else {
                gestureState = .zero
                return
            }

            gestureState =
                value.translation
        }
        .onEnded { value in
            guard state.zoomScale > 1.01 else {
                return
            }

            withAnimation(
                .interactiveSpring(
                    response: 0.32,
                    dampingFraction: 0.86,
                    blendDuration: 0.15
                )
            ) {
                state.finishPan(
                    predictedTranslation:
                        value.predictedEndTranslation,

                    image: image,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight
                )
            }
        }
    }
}
